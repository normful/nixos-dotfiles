---
name: maintain-rpiv-pi-models
description: Maintain models used for rpiv-pi skills and agents
modified: 2026-08-25T00:00:00+0900
---

# maintain-rpiv-pi-models

This skill maintains the **per-user model override file** at
`chezmoi/dot_config/rpiv-pi/private_models.json`
(chezmoi source path; installs to `~/.config/rpiv-pi/private_models.json`).

That file maps AI/LLM models to rpiv-pi agents, stages, skills, and presets,
overriding rpiv-pi's built-in defaults. It is the single place to adjust
which models are used by the agent framework's various components.

## Current model policy

Prefer **task-specific model assignment** rather than using one model everywhere. Use expensive models only for high-intelligence architecture/design work, and use lighter or specialized models for routine coding tasks.

## Current model-role mapping

| Task type | Preferred model |
|---|---|
| Default | `opencode-go/muse-spark-1.2-contributor` |
| Research / implementation / agent work | `opencode-go/muse-spark-1.2-contributor` |
| Planning / code review / revise | `opencode-go/muse-spark-1.2-contributor` *(migrated from `aihubmix-am/cc-minimax-m3` 2026-08-25)* |
| Validation / slice verification | `opencode-go/mimo-v2.5-pro` |
| Blueprint | `opencode-go/muse-spark-1.2-contributor` |
| Architecture / design | `opencode-go/muse-spark-1.2-contributor` |
| Claim verification | `opencode-go/mimo-v2.5-pro` |
| Commit generation | `opencode-go/muse-spark-1.2-contributor` (ship preset: `thinking: minimal`) |
| Visual/frontend design | `opencode-go/deepseek-v4-flash-vision-exp` |

## Low-hallucination models

Use `opencode-go/mimo-v2.5-pro` for tasks requiring rigid adherence to instructions (validation, slice verification, claim verification). `aihubmix-am/cc-minimax-m3` was previously used for planning/code-review/revise for the same reason, but was **retired 2026-08-25** and migrated to `opencode-go/muse-spark-1.2-contributor` — do not reintroduce it.

- `opencode-go/mimo-v2.5-pro`: validation, slice verification, and claim verification (remains authoritative)
- `aihubmix-am/cc-minimax-m3`: **retired** — formerly planning, code review, revise; now `opencode-go/muse-spark-1.2-contributor`

## Current usage

### `opencode-go/muse-spark-1.2-contributor`

Use for default, research, implementation, blueprint, commit, architecture/design, discovery, and agent support:

- Default model
- `stages.commit`
- `skills.commit`
- `stages.research`
- `stages.blueprint`
- `stages.architecture-review`
- `stages.design`
- `agents.codebase-analyzer`
- `agents.artifact-code-reviewer`
- `agents.artifact-coverage-reviewer`
- `agents.scope-tracer`
- `skills.create-handoff`
- `skills.resume-handoff`
- `skills.implement`
- `skills.blueprint`
- `skills.research`
- `skills.design`
- `skills.discover`
- `skills.explore`
- `skills.browser-tool`
- `skills.hunk-review`
- `presets.build.stages.commit`
- `presets.build.stages.implement`
- `presets.build.stages.research`
- `presets.build.stages.blueprint`
- `presets.ship.stages.commit` (thinking: minimal)
- `presets.ship.stages.implement`
- `presets.ship.stages.blueprint`

### `opencode-go/mimo-v2.5-pro`

Use for validation, claim verification, and slice verification (all adversarial code-grounded tasks):

- `agents.claim-verifier`
- `agents.slice-verifier`
- `stages.validate`
- `skills.validate`
- `presets.build.stages.validate` (`thinking: high`)
- `presets.ship.stages.validate` (`thinking: high`)

### `opencode-go/muse-spark-1.2-contributor` — also for planning / code review / revise (migrated)

These were `aihubmix-am/cc-minimax-m3` before 2026-08-25, now Muse:

- `stages.code-review` (`thinking: high`)
- `skills.code-review` (`thinking: high`)
- `skills.plan` (`thinking: high` — was `xhigh`, lowered 2026-08-25)
- `presets.build.stages.code-review` (`thinking: high`)
- `presets.build.stages.revise` (`thinking: high`)

### `opencode-go/deepseek-v4-flash-vision-exp`

Use for visual/frontend design:

- `skills.frontend-design`

This is a vision-capable flash model with image input and visual understanding, so use it for any UI, UX, or visual-related work.

<!-- `openrouter/nex-agi/nex-n2-mini` no longer used; discover/explore now use `opencode-go/muse-spark-1.2-contributor` -->
<!-- `aihubmix-oc/qwen3.8-max-preview` no longer used; architecture/design now use `opencode-go/muse-spark-1.2-contributor` -->

## Maintenance rules

- Keep `skills.frontend-design` on `opencode-go/deepseek-v4-flash-vision-exp` for visual work.
- Keep commit generation on `opencode-go/muse-spark-1.2-contributor` with `thinking: low` or `thinking: minimal` for speed. Use `thinking: minimal` for the ship preset commit stage.
- Use `opencode-go/mimo-v2.5-pro` for validation, slice verification, and claim verification (`thinking: high`).
- Use `opencode-go/muse-spark-1.2-contributor` for code review, planning, and revise (`thinking: high` — migrated from `aihubmix-am/cc-minimax-m3` 2026-08-25; do not reintroduce minimax).
- Use `opencode-go/muse-spark-1.2-contributor` for research, implementation, handoffs, blueprint, architecture/design, and agent support (`thinking: high`; `defaults` is `high`).
- After any change to `private_models.json`, you **must** sync the two downstream skills below — they are not templated and will drift if skipped.

## Downstream sync — required after every `private_models.json` change

> **Why:** The two skills below hard-code the same model IDs. `private_models.json` is the source of truth, but `orchestrator` and `writing-multiagent-workflows` have their own tables/examples that must be kept in sync manually.

### 1. `~/.pi/agent/skills/curated-ai-skills/orchestrator/SKILL.md`

*Full path:* `~/.pi/agent/skills/curated-ai-skills/orchestrator/SKILL.md` (repo: `curated-ai-skills` skill `orchestrator`)

**What to sync:**

| Section in `orchestrator/SKILL.md` | How to update from `private_models.json` |
|---|---|
| `## Model Selection by subagent_type` header note | Keep `Source of truth: ~/.config/rpiv-pi/private_models.json (chezmoi: chezmoi/dot_config/rpiv-pi/private_models.json)` and retired-model list (`aihubmix-oc/deep-deepseek-v4-flash-0731`, `opencode/deepseek-v4-flash-free`, `aihubmix-am/cc-minimax-m3` all retired) |
| Table `\| subagent_type \| model \| thinking \|` | `general-purpose` → `defaults`; `codebase-analyzer` → `agents.codebase-analyzer`; `artifact-code-reviewer`/`artifact-coverage-reviewer` → `agents.*`; `scope-tracer` → `agents.scope-tracer`; `claim-verifier`/`slice-verifier` → `agents.claim-verifier`/`slice-verifier` (`opencode-go/mimo-v2.5-pro / high`); all locator/comparator `codebase-pattern-finder`, `artifacts-locator`, etc. → `defaults` (`opencode-go/muse-spark-1.2-contributor / high`); `commit-related` → `stages.commit`/`skills.commit` (`low`) |
| `> **Notes:**` | Update `defaults is ... / high`, note that `aihubmix-am/cc-minimax-m3` is retired and migrated to Muse, locator `low` → `high` migration note, `frontend-design vision-exp` note stays |
| `For any subagent_type not listed, default to ...` | Must match `defaults` (`opencode-go/muse-spark-1.2-contributor / high`) |
| `# Parameters to use when callling sideagent-start` | `"model": "opencode-go/muse-spark-1.2-contributor"` (must match `defaults.model`) |

**Current authoritative values (2026-08-25):** all Muse entries `high` (was `xhigh`), Mimo entries `high`, Vision `high`, Commit `low`/`minimal` — no `xhigh` remains.

### 2. `~/.pi/agent/skills/curated-ai-skills/writing-multiagent-workflows/SKILL.md`

*Full path:* `~/.pi/agent/skills/curated-ai-skills/writing-multiagent-workflows/SKILL.md` (repo: `curated-ai-skills` skill `writing-multiagent-workflows`)

**What to sync:**

| Section in `writing-multiagent-workflows/SKILL.md` | How to update from `private_models.json` |
|---|---|
| `## 1. Required Header` `model: '...'` example | Must be `model: 'opencode-go/muse-spark-1.2-contributor'` — `defaults.model` |
| `## 2. agent(prompt, options?)` `GOOD` example `model: "..."` | Must be `model: "opencode-go/muse-spark-1.2-contributor"` — `defaults.model` |
| Warning box `e.g. one agentType uses ...` | Example must contrast `opencode-go/mimo-v2.5-pro` (verification) vs `opencode-go/muse-spark-1.2-contributor` (everything else). Note historically `aihubmix-am/cc-minimax-m3` was for `plan`/`code-review` but retired 2026-08-25. Must cite `Source of truth: ~/.config/rpiv-pi/private_models.json` |

**Checklist after editing both files:**
```bash
grep -n "muse-spark\|mimo-v2\|minimax\|deepseek" ~/.pi/agent/skills/curated-ai-skills/orchestrator/SKILL.md ~/.pi/agent/skills/curated-ai-skills/writing-multiagent-workflows/SKILL.md
grep -n '"model"' ~/.config/rpiv-pi/private_models.json | head
```