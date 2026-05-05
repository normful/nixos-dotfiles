# Git

- If you edited files, always git commit related files you edited BEFORE finishing your entire session
    - Run `git add` with the paths of the files you edited. Never blindly stage all files: i.e. never run `git add -A`
    - Commit often, with small groups of related changes in the same commit. Avoid making single commits with many files added.
        - Exception: if you run a format fix or lint fix command that does bulk automatic changes, then you can commit all of those many files together in 1 commit.
- If you see unexpected file edits that YOU did not write, NEVER revert those changes; leave them
- Use conventional commit messages (feat:, fix:, chore:, docs:, etc)
- Renaming one file: ALWAYS run `git mv` (not `mv`) combined with `git commit` in the SAME `bash` tool call.
- NEVER run `git reset --hard` or `git checkout --` or `git restore` unless it is a command only affecting 1 file that YOU changed.I
- If running `git rebase --continue`, prepend `GIT_EDITOR=true` env var.

# File access

DO NOT read or write files outside the current directory, unless user explicitly asks to.
DO NOT run `find` to search for files outside the current directory tree.
If you encounter an 'Operation not permitted' or EPERM error, stop and ask the user about what to do next. Do not try to work around the error.

# System

NEVER run ANY `homebrew` command.

# Conditional Special Behavior

ONLY IF system prompt `<available_skills>` shows a `finish` skill, THEN:
- ALWAYS run git commands with the following additional environment variables. Example: instead of `git commit`, run `GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_EDITOR=cat GIT_AUTHOR_NAME="AI" GIT_AUTHOR_EMAIL="none" GIT_COMMITTER_NAME="AI" GIT_COMMITTER_EMAIL="none" git -c core.excludesFile=/dev/null commit`. Same for all other git commands.
- git commit all changes before using `finish` skill, which is at `<current_dir>/.pi/side-agent-skills/finish/SKILL.md`
- NEVER attempt to `git checkout` ANY OTHER branch

Then when user says "lgtm finish", DO NOT run `ask_user_questions` tool. Proceed to `finish` skill steps.

# When to use different similar browser automation tools & skills

1. When asked to read and understand text content of websites (for researching unknown websites not developed locally), use `chrome-devtools-cli` skill.
2. When inspecting network requests, Lighthouse scores, or performance profiles, use `chrome-devtools-cli` skill.
3. When interacting with a localhost web application, use `playwright-cli` skill first, with `chrome-devtools-cli` as a secondary fallback. Avoid using `browser` tool.
4. When asked to rapidly open many web pages (and not a scenario above), use `browser` tool.

Use `understand_screenshot` tool to get text descriptions of screenshot images.

# Unit tests

When planning, always plan to write AT LEAST unit tests, using red-green TDD. Tests should reduce duplication (DRY), using: setup helper functions (create them if they do not exist), shared assertion utilities (if reduces code repeated more than 3 times), fixtures, factories.

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
