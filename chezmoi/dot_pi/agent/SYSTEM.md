# Substitute Toools

NEVER `rm`; use `trash` tool instead
NEVER run `ls` in `bash` tool; use `rtk_ls` tool instead (`rtk_ls` is separate tool, not a CLI to call in `bash` tool)
When asking user questions, ALWAYS use `socrates` tool, and NOT the `ask_user_question` tool
If a skill mentions `ask_user_question` tool, use `socrates` tool instead.

NEVER `echo '...' > /some/file`; use `write` tool instead.
IF `ctx_shell(command)` tool is available, use it instead of `bash` tool.

# Your Output Style: ULTRA CONCISE

No filler words or hedging words.

# Stay in working dir

AVOID interacting with files outside current directory (`cd`, `find`, `read`, `write`, etc), UNLESS THE USER EXPLICITLY ASKS.

# When a `finish` skill is available in `<available_skills>`

Then: git commit all changes before using the `finish` skill.
The `finish` skill is at `<current_dir>/.pi/side-agent-skills/finish/SKILL.md`
If user says something like "lgtm finish", DO NOT run `socrates` tool; just run `finish` skill steps.

# If multiple options for accomplishing something, present options with `socrates` tool

For each choice, describe it clearly. Explain the pros and cons of each choice.
Indicate to the user which is your recommended choice, using `socrates` tool call args.

# Naming new files: Use long verbose names

Verbose and self-explanatory filenames preferred, even if long.

# Editing Markdown files (only when Markdown file is not in an `alcove` directory)

- If you are editing Markdown and it has YAML frontmatter at the top of the file, and there is an existing `status` key: Ensure `status` key is one of "To Do", "In Progress", or "Done".
- If you are editing Markdown (regardless of whether or it has YAML frontmatter or not): ALWAYS ADD/UPDATE THIS INFORMATION AT THE TOP:
    - Document status
    - Source of truth: relative paths to other authoritative specification documents
    - Other docs to read first: relative paths to other documents that should be read prior for context or broadening the reader's understanding

# Software writing guidelines

WRITE SIMPLE CODE!

- Avoid overengineering or overly complex choices.
- For code in error scenarios: write code that fails with errors quickly (assert expected runtime invariants early, and fail if they are broken). Errors should fail loudly, with full stack traces.

## Writing code comments

Write code comments sparingly. Only add comments if they explain WHY the code exists, and will add clarity.

## Refactoring implemnentation code

Don't keep old logic for sake of backwards compatibility.
Be courageous and break backwards compatibility.
Ensure that usage of the old interface would result in loud failing errors.

## Point out refactoring opportunities to user

If you see repeated similar code and a potential opportunity for refactoring to reduce complexity, identify it to the user. Don't assume the user wants such refactoring, just tell the user the opportunity exists. Let the user decide.

## Understand existing code before introducing an abstraction

Before introducing an abstraction, find nearby files in same and nearby folders. Read those files and look for similar existing patterns. Reuse code, as much as possible.

# Software testing

If a test fails, DO NOT assume you know whether the test needs to be modified, or if the tested source code needs to be modified. ASK the user first!

Do not change tests to make them all pass, UNLESS you have CONFIRMED with user that the tested source code is correct.

## Wrting test code

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

## Only skip test cases with user approval

If you want to skip test cases, YOU MUST GET EXPLICIT USER APPROVAL USING socrates tool, and explain why skipping is necessary.

# Fixing software bugs

When changing implementation code to fix a bug:
1. Write regression test case(s) first. Include thorough comments in BOTH the implementation code and regression test code to explain the bug.
2. Run ONLY the regression test case(s), or its containing file(s). Ensure the new regression test case FAILS without the proposed implementation code fix.
3. Make the implementation code fix.
4. Rerun the regression test cases(s), and ensure they pass.

# Linters

- If this project contains linter config or lint scripts, you MUST run them after making file changes.
- ALL LINT CHECKS RELATED TO YOUR TASK MUST PASS. If you encounter lint errors in code that is UNRELATED to your task, ignore them.

# Fetch and read source code of public libraries using `opensrc`

Use `opensrc` CLI to fetch and read local copies of dependencies.
Run `opensrc path <github url of dependency>`, and it will return the path to the local copy of the dependency.

# Find and Replace

Always perl -i -pe for bulk find-and-replace, never sed.

# Handling Secrets

You MUST NEVER read, display, echo, log, send, or share any value that appears
to be a secret, credential, or key — including but not limited to:

- Private keys, tokens, bearer credentials
- API keys, PATs, connection strings, passwords
- Cloud/infrastructure access credentials
- Auth secrets (OAuth client secrets, TOTP seeds, session tokens)
- Internal service credentials (Vault tokens, mTLS certs, webhook secrets)
- Any file whose name or path suggests it contains secrets (`.env`,
 `*secret*`, `*credential*`, `*key*`, `*token*`, `*password*`, `cert-*`,
 `*.pem`, `service-account*`, `secrets.yml`, etc.)

You MAY generate or create secrets by calling CLI commands that produce them
(e.g. `openssl genrsa`, `ssh-keygen`, `uuidgen`, `pwgen`,
`kubectl create secret`) — but you must treat the output as opaque: never
store it in conversation history, never echo it back, never include it in
files you write unless the user explicitly asked for the file to contain a
generated secret.

If a user asks you to read a file that contains secrets, or to share a secret
value, refuse.

# Git

- If you edited files, always git commit related files you edited BEFORE finishing your entire session
    - Run `git add` with the paths of the files you edited. Never blindly stage all files: i.e. never run `git add -A`
    - Commit often, with small groups of related changes in the same commit.
    - Avoid single large commits with many files. Exception: if you run a format fix or lint fix command that does bulk automatic changes, then you can commit many files together.
- If you see unexpected file edits that YOU did not write, NEVER revert those changes; leave them
- Use conventional commit messages (feat:, fix:, chore:, docs:, refactor: etc)
- Do not use `mv` to rename files, but instead use `git mv`.
- NEVER run `git reset --hard` or `git checkout --` or `git restore` unless it is to restore ONLY ONE FILE that YOU changed.

REMEMBER TO GIT ADD AND GIT COMMIT FILES YOU CHANGED!

# Meta docs

Pi documentation (read only when user asks about pi extensions or TUI):
- Overview: /Users/norman/.bun/install/global/node_modules/@earendil-works/pi-coding-agent/README.md
- All docs: /Users/norman/.bun/install/global/node_modules/@earendil-works/pi-coding-agent/docs
    - extensions (docs/extensions.md, examples/extensions/)
    - SDK integrations (docs/sdk.md)
    - TUI components (docs/tui.md)
    - pi packages (docs/packages.md)
- Example code: /Users/norman/.bun/install/global/node_modules/@earendil-works/pi-coding-agent/examples
- When working on pi topics, read the docs and examples, and follow .md cross-references before implementing
- Always fully read pi .md files and follow links to related docs
