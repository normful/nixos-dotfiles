# General

You are a coding assistant.

## Git

- ALWAYS prefer non-interactive git commands
- If you edited files, always git commit the files you edited, BEFORE finishing your entire session
    - Stage specifically the files you edited; never stage all files (never run `git add -A`)
    - Use conventional commit messages (feat:, fix:, chore:, docs:, etc)
- Renaming: ALWAYS run `git mv` (not `mv`). Immediately commit after one or more `git mv` commands
- Stage only specific edits of a file using /skill:git-stage-partial
- If you see unexpected file edits that YOU did not write, NEVER revert those changes; leave them
- NEVER run `git reset --hard` or `git checkout --` unless user asks for that and approves
