#!/usr/bin/env bash
set -euo pipefail

PARENT_ROOT="${PI_SIDE_PARENT_REPO:-${1:-}}"
AGENT_ID="${PI_SIDE_AGENT_ID:-${2:-unknown}}"
MAIN_BRANCH="new-main-wip"

export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME="AI"
export GIT_AUTHOR_EMAIL="none"
export GIT_COMMITTER_NAME="AI"
export GIT_COMMITTER_EMAIL="none"

BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
if [[ "$BRANCH" == "HEAD" ]]; then
  BRANCH=""
fi

if [[ -z "$PARENT_ROOT" ]]; then
  echo "Missing parent checkout path."
  echo "Usage: PI_SIDE_PARENT_REPO=/path/to/parent .pi/side-agent-finish.sh"
  exit 1
fi

if [[ -z "$BRANCH" ]]; then
  echo "Could not determine current branch."
  exit 1
fi

LOCK_DIR="$PARENT_ROOT/.pi/side-agents"
LOCK_FILE="$LOCK_DIR/merge.lock"
mkdir -p "$LOCK_DIR"

MERGE_LOCK_TIMEOUT=120

iso_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

acquire_lock() {
  local payload started elapsed
  payload="{\"agentId\":\"$AGENT_ID\",\"pid\":$$,\"acquiredAt\":\"$(iso_now)\"}"
  started=$(date +%s)
  while true; do
    if ( set -o noclobber; printf '%s\n' "$payload" > "$LOCK_FILE" ) 2>/dev/null; then
      return 0
    fi
    elapsed=$(( $(date +%s) - started ))

    # Check if the lock holder is still alive (stale lock after crash/reboot)
    if [[ -f "$LOCK_FILE" ]]; then
      local holder_pid
      holder_pid="$(grep -o '"pid":[0-9]*' "$LOCK_FILE" 2>/dev/null | head -n 1 | grep -o '[0-9]*' || true)"
      if [[ -n "$holder_pid" ]] && ! kill -0 "$holder_pid" 2>/dev/null; then
        echo "Removing stale merge lock (pid $holder_pid no longer running)."
        rm -f "$LOCK_FILE"
        continue
      fi
    fi

    if [[ "$elapsed" -ge "$MERGE_LOCK_TIMEOUT" ]]; then
      echo "Timed out after ${MERGE_LOCK_TIMEOUT}s waiting for merge lock."
      echo "Stale lock? Inspect: $LOCK_FILE"
      exit 3
    fi
    echo "Waiting for merge lock... (${elapsed}s / ${MERGE_LOCK_TIMEOUT}s)"
    sleep 1
  done
}

release_lock() {
  rm -f "$LOCK_FILE" || true
}

trap 'release_lock' EXIT

while true; do
  echo "Running: 'git rebase $MAIN_BRANCH' to replay $BRANCH commits on top of $MAIN_BRANCH"
  if ! git rebase "$MAIN_BRANCH"; then
    echo "Conflict while rebasing $BRANCH onto $MAIN_BRANCH."
    echo "Resolve conflicts (git status / git rebase --continue), then rerun .pi/side-agent-finish.sh"
    exit 2
  fi

  acquire_lock

  set +e
  (
    git -C "$PARENT_ROOT" checkout "$MAIN_BRANCH" >/dev/null 2>&1 || exit 1
    git -C "$PARENT_ROOT" merge --no-ff "$BRANCH"
  )
  merge_status=$?
  set -e

  release_lock

  if [[ "$merge_status" -eq 0 ]]; then
    echo "Success: $BRANCH was merged into $MAIN_BRANCH"
    rm -f "$(pwd)/.pi/active.lock" || true
    exit 0
  fi

  echo "Merge failed (likely $MAIN_BRANCH moved)"
  echo "Retrying loop..."

  sleep 1
done
