---
name: finish
description: Rebase the branch with current work onto parent and merge it, after user approves (e.g. 'lgtm finish')
---

# Parallel-agent finish workflow

When the user explicitly approves the work (e.g. says "LGTM", "ship it", "merge it", "lgtm finish"):

1. Use the bash tool to show the value of the $PI_SIDE_PARENT_REPO env var.
2. Run the finish script and explicitly pass the found value of PI_SIDE_PARENT_REPO from prev step. Example: `PI_SIDE_PARENT_REPO="/Users/somebody/some/path" .pi/side-agent-finish.sh`
3. If the finish script exits with code 2 (conflict rebasing child branch onto new-main-wip):
   - Stay in this worktree
   - Resolve conflicts (`git status`, then `GIT_EDITOR=true git rebase --continue`)
   - Re-run the finish script after the rebase completes
4. If the merge fails because new-main-wip moved ahead:
   - The finish script retries the reconcile loop automatically
   - Attempt to solve simple issues yourself, but escalate to the user with major issues (such as dirty parent worktree)
5. After success: report the landed commit(s). Suggest `/quit` if no further work is needed.
