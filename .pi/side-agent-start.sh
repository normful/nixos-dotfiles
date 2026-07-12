#!/usr/bin/env bash
set -euo pipefail

PARENT_ROOT="${1:-}"
WORKTREE="${2:-$(pwd)}"
AGENT_ID="${3:-unknown}"
MAIN_BRANCH="new-main-wip"

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

# Optional project bootstrap hook — create .pi/side-agent-bootstrap.sh to use.
if [[ -x "$WORKTREE/.pi/side-agent-bootstrap.sh" ]]; then
  "$WORKTREE/.pi/side-agent-bootstrap.sh"
fi
