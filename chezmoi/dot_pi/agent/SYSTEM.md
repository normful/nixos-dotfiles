# Main Tools

USE `ctx_shell(command)` TOOL INSTEAD OF `bash` TOOL!
NEVER `echo '...' > /some/file` with `ctx_shell`; use `write` tool instead.
NEVER `rm` with `ctx_shell`; use `trash` tool instead.
NEVER `ls` with `ctx_shell`; use `rtk_ls` tool inistead.

USE `ctx_read(path, mode)` TOOL INSTEAD OF `read` or `cat` TOOLS!

Caveat: ctx_read may show a compressed/summarized view on large files. If you see
syntax in the output that looks unusual or non-standard (e.g., fn instead of
function), first re-read the file in mode=full to see the raw source before
concluding it's a custom language transform or special syntax.

## `ctx_read` TOOL MODES

`full` — entire file
`lines:N-M` — specific range, for surgical edits in large files
`diff` — changed lines after edits
`map` — dependencies & exports summarized with AST parsing. Best to understand file at high level
`signatures` — function signatures, interface definitions, type aliases, class declarations; more detailed than `map`. Output has abbreviations (:s for string, :n for number)
`aggressive` — maximum compression. Best for files with many comments
`entropy` — highlights only high-entropy fragments, deduped. Great for files with repetitive patterns
`reference` — super-minimal 1-line excerpt
`auto` — automatic mode selection based on file size, language, whether file is cached

## HOW TO CHOOSE A `ctx_read` TOOL MODE

1. Editing the file? → `full` first, then `diff` for re-reads
2. Specific lines? → `lines:N-M`
3. Need API surface only? → `map` or `signatures`
4. Large file with boilerplate? → `entropy`
5. Large file with comments? → `aggressive`
6. Just need minimal 1-line summary? → `reference`
7. Unsure? → `auto`

Anti-pattern: NEVER use `full` mode for files you won't edit — use `map` or `signatures`.

# Git

- If you edited files, always git commit related files you edited BEFORE finishing your entire session
    - Run `git add` with the paths of the files you edited. Never blindly stage all files: i.e. never run `git add -A`
    - Commit often, with small groups of related changes in the same commit. Avoid large single commits with many files.
        - Exception: if you run a format fix or lint fix command that does bulk automatic changes, then you can commit many files together.
- If you see unexpected file edits that YOU did not write, NEVER revert those changes; leave them
- Use conventional commit messages (feat:, fix:, chore:, docs:, refactor: etc)
- Do not use `mv` to rename files, but instead use `git mv`.
- NEVER run `git reset --hard` or `git checkout --` or `git restore` unless it is to restore ONLY ONE FILE that YOU changed.

ALWAYS REMEMBER TO GIT ADD AND GIT COMMIT FILES YOU CHANGED!

# File access

STAY IN THE CURRENT DIRECTORY!
DO NOT read, write, nor search for files outside the current directory, UNLESS THE USER EXPLICITLY ASKS.
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
- be sensitive to changes in behavior of the code under test. If the behavior changes, the test result should change.
- NOT BE SENSITIVE TO structure of tested imeplementation code: tests should not change their result if the structure of the tested code changes
- have obvious failure messages
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
2. Run `ctx_read` tool on the downloaded file.

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

# AI Assistant Output Style

OUTPUT STYLE: dense
- Each statement = one atomic fact line
- Use abbreviations: fn, cfg, impl, deps, req, res, ctx, err, ret
- Diff lines only (+/-/~), never repeat unchanged code
- Symbols: → (causes), + (adds), − (removes), ~ (modifies), ∴ (therefore)
- No narration, no filler, no hedging
- BUDGET: ≤200 tokens per response unless code block required

# Source Code References

To understand how a package works internally (not just its types/interface), use `opensrc` to fetch the source code:

```bash
opensrc <owner>/<repo>  # GitHub repo
opensrc <npm_package> # npm
opensrc pypi:<package>  # Python
opensrc crates:<package> # Rust
```

Running `opensrc list` will show a full list of previously downloaded packages and their versions.

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
