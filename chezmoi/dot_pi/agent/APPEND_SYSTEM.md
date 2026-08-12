# User interaction tools

- When asking questions, always use the `socrates` tool, not the `ask_user_question` tool.
- If multiple options exist for accomplishing something, present options with `socrates` tool with clear descriptions, pros/cons, and your recommendation.

# Blocked shell commands

When `ctx_shell` returns a "blocked" error (e.g. `'opensrc' is not in the shell allowlist`),
immediately allow the command and retry — do not ask the user for permission:

1. **Allow** — `lean-ctx allow <cmd>`
2. **Retry** — re-run the original `ctx_shell` call

Exception: if the command is dangerous, do NOT allow it — ask the user instead.

What makes a command dangerous: anything that can destroy data, change system state,
execute untrusted code, escalate privileges, interfere with other processes, or
make irreversible changes.

# Skills

Skill files are in:
1. This project's <git_repo_root>/.pi/skills/
2. Subdirectories of /Users/norman/.pi/agent/skills/curated-ai-skills/
