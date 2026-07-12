---
name: agent-setup
description: Initialize or update setup for pi-side-agents (running asynchronous agents spawned into their own new tmux windows)
modified: 2026-07-12T01:34:43+0900
---

# Parallel Agent Setup

Set up the pi-side-agents lifecycle scripts for this project.

Initial first time setup (no .pi/side-agent* yet): Work through two phases: interview, then file creation.
Finish by backing up this agent-setup SKILL.md to .pi/side-agents/agent-start~/ for easy future upgrades.

Update setup: Chat with the user about what needs changing, use file examples below as reference for comparison.

Upgrade setup to new pi-side-agents version: Diff this file with the current backup `.pi/side-agents/agent-start~/`
and discuss the changes to apply (or not) with the user. When upgrade is finished, update the backup to the current version.

**`.gitignore` and commit policy:** Most files under `.pi/` should be committed. Only two paths are runtime-only and must be gitignored. Before creating phase-2 files, execute this workflow:

1. If the repo has no `.gitignore` yet, create one.
2. Read the current `.gitignore`. If these patterns are not already present, append them:
   ```gitignore
   .pi/side-agents/registry.json
   .pi/side-agents/runtime/
   ```
3. After creating all phase-2 files (below), run:
   ```bash
   git add .pi/side-agent-start.sh .pi/side-agent-finish.sh .pi/side-agent-bootstrap.sh
   git add .pi/side-agents/agent-start~/
   git add .pi/side-agents/finish/
   git add .gitignore
   ```
4. Commit everything with a message like `chore: add pi-side-agents setup`.
5. Verify no `.pi` runtime files leaked into the commit: `git diff --cached --name-only | grep -c '\.pi/side-agents/registry\.json'` should be 0.

## Phase 1: Interview

Ask the user the following questions. You may ask them all at once or one at a time — use your judgment based on how they engage.

1. **Main branch name** – What is the primary integration branch? *(default: `main`)*

2. **Bootstrap steps** – Does each agent worktree need custom setup before work begins? For example: `npm install`, copying `.env` files, running migrations. If yes, what commands specifically?

3. **Finish policy** – When an agent finishes, should it:
   - Rebase locally then merge into the main branch in the parent checkout (default), or
   - Open a pull request instead?

4. **Overwrite existing files** – If `.pi/side-agent-start.sh` or similar already exist, overwrite them? *(default: no — skip existing files)*

Before asking the questions, autonomously try to answer questions 1, 2 and 4, and propose project-specific answers to the user.

Collect all answers before proceeding to Phase 2.

---

## Phase 2: Create Setup Files

Determine the git repo root:

```bash
GIT_ROOT=$(git rev-parse --show-toplevel)
```

Create the three files below. For each file, check whether it already exists before writing — if it exists and the user said not to overwrite, skip it and tell the user. Otherwise write (or overwrite) it.

---

### File 1: `$GIT_ROOT/.pi/side-agent-start.sh`

Write this file and make it executable (`chmod +x`).

Use `MAIN_BRANCH` set to whatever the user specified in question 1 (or `main` by default). The start script validates the branch but does **not** reset HEAD — the TypeScript extension already sets the worktree to the parent's HEAD. Do **not** force-update the local `MAIN_BRANCH` ref (e.g. `git branch -f`) because that branch is often checked out in the parent worktree.

**Default content** — substitute `MAIN_BRANCH_VALUE` with the actual branch name, then append bootstrap steps based on question 2:

```bash
#!/usr/bin/env bash
set -euo pipefail

PARENT_ROOT="${1:-}"
WORKTREE="${2:-$(pwd)}"
AGENT_ID="${3:-unknown}"
MAIN_BRANCH="MAIN_BRANCH_VALUE"

BRANCH="$(git -C "$WORKTREE" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
if [[ -z "$BRANCH" ]] || [[ "$BRANCH" == "HEAD" ]]; then
  echo "Could not determine current branch in $WORKTREE"
  exit 1
fi

echo "agent=$AGENT_ID branch=$BRANCH main=$MAIN_BRANCH"

if [[ "$BRANCH" == "$MAIN_BRANCH" ]]; then
  echo "ERROR: child worktree is on $MAIN_BRANCH; expected a dedicated agent branch."
  exit 1
fi

# The worktree is already set to the parent's HEAD by the TypeScript extension.
# Just verify it's on the right branch.
echo "Worktree based on parent HEAD ($(git -C "$WORKTREE" rev-parse --short HEAD))."
```

- If the user wants **no custom bootstrap**: append the optional hook block:
  ```bash
  # Optional project bootstrap hook — create .pi/side-agent-bootstrap.sh to use.
  if [[ -x "$WORKTREE/.pi/side-agent-bootstrap.sh" ]]; then
    "$WORKTREE/.pi/side-agent-bootstrap.sh"
  fi
  ```

- If the user gave **specific bootstrap commands**: append them directly instead, e.g.:
  ```bash
  # Project bootstrap
  cd "$WORKTREE"
  npm install
  cp .env.example .env 2>/dev/null || true
  ```

---

### File 2: `$GIT_ROOT/.pi/side-agent-finish.sh`

Write this file and make it executable (`chmod +x`).

Use `MAIN_BRANCH` set to whatever the user specified (or `main` by default).

**For local rebase and merge policy** (default), use this content — substituting `MAIN_BRANCH_VALUE` with the actual branch name:

```bash
#!/usr/bin/env bash
set -euo pipefail

PARENT_ROOT="${PI_SIDE_PARENT_REPO:-${1:-}}"
AGENT_ID="${PI_SIDE_AGENT_ID:-${2:-unknown}}"
MAIN_BRANCH="MAIN_BRANCH_VALUE"

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
```

**For PR policy**: write a finish script that pushes the branch and opens a PR via the `gh` CLI:

```bash
#!/usr/bin/env bash
set -euo pipefail

AGENT_ID="${PI_SIDE_AGENT_ID:-${1:-unknown}}"
MAIN_BRANCH="MAIN_BRANCH_VALUE"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
if [[ "$BRANCH" == "HEAD" ]]; then
  BRANCH=""
fi

echo "Pushing $BRANCH..."
git push -u origin "$BRANCH"

echo "Opening pull request against $MAIN_BRANCH..."
gh pr create --base "$MAIN_BRANCH" --head "$BRANCH" --fill
```

---

### File 3: `$GIT_ROOT/.pi/side-agents/finish/SKILL.md`

This is a skill for the **child agent** (not this session) that tells it how to finalize its work.

**For local rebase policy**, write:

```markdown
---
name: finish
description: Rebase the branch with current work onto parent and merge it, after user approves (e.g. 'lgtm finish')
---

# Parallel-agent finish workflow

When the user explicitly approves the work (e.g. says "LGTM", "ship it", "merge it", "lgtm finish"):

1. Use the bash tool to show the value of the $PI_SIDE_PARENT_REPO env var.
2. Run the finish script and explicitly pass the found value of PI_SIDE_PARENT_REPO from prev step. Example: `PI_SIDE_PARENT_REPO="/Users/somebody/some/path" .pi/side-agent-finish.sh`
3. If the finish script exits with code 2 (conflict rebasing child branch onto MAIN_BRANCH_VALUE):
   - Stay in this worktree
   - Resolve conflicts (`git status`, then `GIT_EDITOR=true git rebase --continue`)
   - Re-run the finish script after the rebase completes
4. If the merge fails because MAIN_BRANCH_VALUE moved ahead:
   - The finish script retries the reconcile loop automatically
   - Attempt to solve simple issues yourself, but escalate to the user with major issues (such as dirty parent worktree)
5. After success: report the landed commit(s). Suggest `/quit` if no further work is needed.
```

**For PR policy**, write a simpler finish skill:

```markdown
---
name: finish
description: Open a PR for the branch with current work to upstream after user approves (e.g. 'lgtm finish')
---

# Parallel-agent finish workflow

When the user explicitly approves the work (e.g. says "LGTM", "ship it", "merge it", "lgtm finish"):

1. Run the finish script to push the branch and open a PR automatically: `.pi/side-agent-finish.sh`
2. Suggest `/quit` if no further work is needed.
```

## Phase 3: Report

Tell the user which files were created, updated, or skipped, including backup/reference files, and how to proceed.

Remind the user that the commit was already created in the `.gitignore` check step above, covering:

| File | Status |
|------|--------|
| `.pi/side-agent-start.sh` | committed |
| `.pi/side-agent-finish.sh` | committed |
| `.pi/side-agents/agent-start~/` | committed (backup of SKILL.md) |
| `.pi/side-agents/finish/SKILL.md` | committed |
| `.pi/side-agents/registry.json` | gitignored (runtime state) |
| `.pi/side-agents/runtime/` | gitignored (per-agent live data) |
| `.gitignore` | updated and committed |

Tell user they can now:
- Start an agent protected by cco: `/safe-agent <task description>`
- Start an agent without cco protection: `/unsafe-agent <task description>`
- List running agents: `/agents`
- Ask you (assistant) to set up and manage a flock of multiple sideagents own to solve a task (you have the tools)
