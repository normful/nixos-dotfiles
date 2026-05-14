# Tools

`bash` tool disallowed. Try using other tools instead. If you REALLY cannot find a way to accomplish something without `bash`, stop and ask user.
No `cat` tool; use `read` tool instead.
`git` tool always uses current directory already (no need to `cd` first).
`npx` is disallowed; ask user.
Don't attempt `echo '...' > /some/file`. Use `write` tool instead.
Use `rg` tool instead of grep.

# Git

- If you edited files, always git commit related files you edited BEFORE finishing your entire session
    - Run `git add` with the paths of the files you edited. Never blindly stage all files: i.e. never run `git add -A`
    - Commit often, with small groups of related changes in the same commit. Avoid large single commits with many files.
        - Exception: if you run a format fix or lint fix command that does bulk automatic changes, then you can commit many files together.
- If you see unexpected file edits that YOU did not write, NEVER revert those changes; leave them
- Use conventional commit messages (feat:, fix:, chore:, docs:, refactor: etc)
- Do not use `mv` to rename files, but instead use `git mv`.
- NEVER run `git reset --hard` or `git checkout --` or `git restore` unless it is to restore ONLY ONE FILE that YOU changed.
- NEVER bypass precommit git hooks

# File access

DO NOT read, write, nor find files outside the current directory, unless user explicitly asks to.
If 'Operation not permitted' or EPERM error, do not try to work around the error.

# When there is a `finish` skill available in `<available_skills>`

Then: git commit all changes before using the `finish` skill.
The `finish` skill is at `<current_dir>/.pi/side-agent-skills/finish/SKILL.md`
If user says something like "lgtm finish", DO NOT run `socrates` tool; just run `finish` skill steps.

# Testing

## Planning and Writing Tests

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

## Running Tests

- ALL TESTS MUST PASS, NOT TIME OUT, NOT HAVE ERRORS
- If you want to remove, disable, or skip tests, YOU MUST GET EXPLICIT USER APPROVAL USING socrates tool

# Linters

- If this project contains linter config or lint scripts, you MUST run them after making file changes.
- ALL LINT CHECKS MUST PASS AND NOT HAVE ERRORS. But if you encounter lint errors in code that is NOT RELATED to what the user asked you to do, use `socrates` tool to seek user guidance

# Markdown document metadata

At the top of each Markdown document, include:
- Document status
- Source of truth: relative paths to other authoritative specification documents
- Other docs to read first: relative paths to other documents that should be read for overview or prerequisite understanding

# Reading code or Markdown files from the internet

1. Run `curl` tool to download the file to `/tmp`.
2. Run `read` tool on the downloaded file.

# Minimize complexity when writing code. WRITE SIMPLE CODE

Avoid overengineering.
Avoid fallback logic in code that would cause invalid subcases to silently be ignored.
For code in error scenarios: write code that fails with errors quickly (assert expected runtime invariants early, and fail if they are broken). Errors should fail loudly, with full stack traces.
When refactoring code, don't keep old logic for sake of backwards compatibility. Be courageous and break backwards compatibility. Ensure that usage of the old interface would result in loud failing errors.
Before introducing an abstraction, find nearby files in same and nearby folders. Read those files and look for similar existing patterns. Reuse code, as much as possible.
If you see repeated similar code and a potential opportunity for refactoring to reduce complexity, identify it to the user. Don't assume the user wants such refactoring, just tell the user the opportunity exists. Let the user decide.

# Writing code comments

Write code comments sparingly. Only add comments if they explain WHY the code exists, and will add clarity.

# Naming new files

When choosing new filenames, use a verbose and self-explanatory filename, even if leads to unusually long filename.

# Fixing bugs

Whenever changing code to fix a bug, you MUST write a regression test case first, using red-green TDD. The test case MUST have a description explaining the bug concisely, and thorough inline comments explaining what the test does.

# Meta docs

Pi documentation (read only when the user asks about pi extensions or TUI):
- Overview: /Users/norman/.bun/install/global/node_modules/@earendil-works/pi-coding-agent/README.md
- All docs: /Users/norman/.bun/install/global/node_modules/@earendil-works/pi-coding-agent/docs
    - extensions (docs/extensions.md, examples/extensions/)
    - themes (docs/themes.md)
    - skills (docs/skills.md)
    - prompt templates (docs/prompt-templates.md)
    - TUI components (docs/tui.md)
    - keybindings (docs/keybindings.md)
    - SDK integrations (docs/sdk.md)
    - custom providers (docs/custom-provider.md)
    - adding models (docs/models.md)
    - pi packages (docs/packages.md)
- Example code: /Users/norman/.bun/install/global/node_modules/@earendil-works/pi-coding-agent/examples
- When working on pi topics, read the docs and examples, and follow .md cross-references before implementing
- Always read pi .md files completely and follow links to related docs
