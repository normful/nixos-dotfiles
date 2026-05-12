# Tools

No `bash` tool
No `cat` tool; use `read` tool instead

# Git

- If you edited files, always git commit related files you edited BEFORE finishing your entire session
    - Run `git add` with the paths of the files you edited. Never blindly stage all files: i.e. never run `git add -A`
    - Commit often, with small groups of related changes in the same commit. Avoid large single commits with many files.
        - Exception: if you run a format fix or lint fix command that does bulk automatic changes, then you can commit many files together.
- If you see unexpected file edits that YOU did not write, NEVER revert those changes; leave them
- Use conventional commit messages (feat:, fix:, chore:, docs:, refactor: etc)
- Do not use `mv` to rename files. Instead, `git mv` combined with `git commit` together in the SAME `bash` call. Example: `git mv docs/a.md docs/COMPLETED-a.md && git commit -m "docs: mark plan as completed"`
- NEVER run `git reset --hard` or `git checkout --` or `git restore` unless it is to restore ONLY ONE FILE that YOU changed.I
- If running `git rebase --continue`, prepend `GIT_EDITOR=true` env var.

# File access

DO NOT read, write, nor find files outside the current directory, unless user explicitly asks to.
If 'Operation not permitted' or EPERM error, do not try to work around the error.

# This is a macOS machine

NEVER run `homebrew`.

# Conditional Special Behavior

ONLY WHEN system prompt `<available_skills>` shows a `finish` skill, THEN:
- ALWAYS run git commands with the following additional environment variables. Example: instead of `git commit`, run `GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_EDITOR=cat GIT_AUTHOR_NAME="AI" GIT_AUTHOR_EMAIL="none" GIT_COMMITTER_NAME="AI" GIT_COMMITTER_EMAIL="none" git -c core.excludesFile=/dev/null commit`. Same for all other git commands.
- git commit all changes before using `finish` skill, which is at `<current_dir>/.pi/side-agent-skills/finish/SKILL.md`

If user says something like "lgtm finish", DO NOT run `ask_user_questions` tool; run `finish` skill steps.

# Testing

When planning, always plan and describe red-green TDD test cases.

Tests MUST:
- minimize duplication (DRY)
    - use helper test functions (create if not existing, but first search and look at what helpers exist)
    - use shared functions to deduplicate common `expect` or `assert` calls
    - use shared setup (fixtures, factories, etc)
- return same results regardless of execution order
- run quickly
- be readable
- be sensitive to changes in behavior of the code under test. If the behavior changes, the test result should change.
- NOT BE SENSITIVE TO structure of tested imeplementation code: tests should not change their result if the structure of the tested code changes
- have failure messages that are obvious and easy to read
- cover scenarios that can actually occur in production

# Markdown document metadata

At the top of each Markdown document, include:
- Document status
- Source of truth: relative paths to other authoritative specification documents
- Other docs to read first: relative paths to other documents that should be read for overview or prerequisite understanding

# Reading code or Markdown files from the internet

1. Run curl via `bash` tool to download the file to `/tmp`.
2. Run `read` tool on the downloaded file.

# Write simple code, minimize complexity

1. Avoid fallback logic in code that would cause invalid subcases to silently be ignored.
2. For code in error scenarios: write code that fails with errors quickly (assert expected runtime invariants early, and fail if they are broken). Errors should fail loudly, with full stack traces.
3. When refactoring code, don't keep old logic for sake of backwards compatibility. Be courageous and break backwards compatibility. Ensure that usage of the old interface would result in loud failing errors.
4. Before introducing an abstraction, use `bash` command to list nearby files in same folders. Read those files and look for similar existing patterns. Reuse code, as much as possible.
5. If you see repeated similar code and a potential opportunity for refactoring to reduce complexity, identify it to the user. Don't assume the user wants such refactoring, just tell the user the opportunity exists. Let the user decide.

# Naming new files

When choosing new filenames, use a verbose and self-explanatory filename, even if leads to unusually long filename.

# Fixing bugs

Whenever changing code to fix a bug, you MUST write a regression test case first, using red-green TDD. The test case MUST have a description explaining the bug concisely, and thorough inline comments explaining what the test does.
