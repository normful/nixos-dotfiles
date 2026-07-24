---
name: maintain-rpiv-pi-models
description: Maintain models used for rpiv-pi skills and agents
modified: 2026-07-21T17:14:15+0900
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
| Default | `aihubmix-oc/deep-deepseek-v4-flash` |
| Visual/frontend design | `aihubmix-am/xiaomi-mimo-v2.5` |
| Research / implementation / agent work | `aihubmix-oc/deep-deepseek-v4-flash` |
| Planning / code review / revise | `aihubmix-am/cc-minimax-m3` |
| Validation / slice verification | `aihubmix-oc/coding-xiaomi-mimo-v2.5-pro` |
| Blueprint | `aihubmix-oc/deep-deepseek-v4-flash` |
| Architecture / design | `aihubmix-oc/qwen3.8-max-preview` |
| Claim verification | `aihubmix-oc/coding-xiaomi-mimo-v2.5-pro` |
| Commit generation | `aihubmix-oc/deep-deepseek-v4-flash` (ship preset: `thinking: minimal`) |

## Low-hallucination models

Use `aihubmix-am/cc-minimax-m3` and `aihubmix-oc/coding-xiaomi-mimo-v2.5-pro` for tasks requiring rigid adherence to instructions. Both have low hallucination rates, so they are good choices when the model must follow constraints, preserve facts, and avoid inventing details.

- `aihubmix-am/cc-minimax-m3`: planning, code review, and revise
- `aihubmix-oc/coding-xiaomi-mimo-v2.5-pro`: validation and slice verification

## Fast-response model

Use `openrouter/nex-agi/nex-n2-mini` for things requiring rapid responses. It is the fastest model in the current configuration, so it is best suited for lightweight tasks such as discovery, exploration, claim verification, and quick turnaround where speed matters more than deep reasoning.

## Current usage

### `openrouter/nex-agi/nex-n2-mini`

Use for lightweight tasks:

- `skills.discover`
- `skills.explore`

### `aihubmix-oc/deep-deepseek-v4-flash`

Use for default, research, implementation, blueprint, commit, and agent support:

- Default model
- `stages.commit`
- `skills.commit`
- `stages.research`
- `stages.blueprint`
- `agents.codebase-analyzer`
- `agents.artifact-code-reviewer`
- `agents.artifact-coverage-reviewer`
- `agents.scope-tracer`
- `skills.create-handoff`
- `skills.resume-handoff`
- `skills.implement`
- `skills.blueprint`
- `skills.research`
- `skills.browser-tool`
- `skills.hunk-review`
- `presets.build.stages.commit`
- `presets.build.stages.implement`
- `presets.build.stages.research`
- `presets.build.stages.blueprint`
- `presets.ship.stages.commit` (thinking: minimal)
- `presets.ship.stages.implement`
- `presets.ship.stages.blueprint`

### `aihubmix-oc/qwen3.8-max-preview`

Use sparingly for expensive high-intelligence architecture/design work:

- `stages.architecture-review`
- `stages.design`
- `skills.design`

Do **not** use qwen3.8 for commits, routine research, planning, blueprint, validation, slice verification, claim verification, or code review unless there is a specific reason.

### `aihubmix-oc/coding-xiaomi-mimo-v2.5-pro`

Use for validation, claim verification, and slice verification (all adversarial code-grounded tasks):

- `agents.claim-verifier`
- `agents.slice-verifier`
- `stages.validate`
- `skills.validate`
- `presets.build.stages.validate`
- `presets.ship.stages.validate`

### `aihubmix-am/cc-minimax-m3`

Use for planning, code review, and revision:

- `stages.code-review`
- `skills.code-review`
- `skills.plan`
- `presets.build.stages.code-review`
- `presets.build.stages.revise`

### `aihubmix-am/xiaomi-mimo-v2.5`

Use for visual/frontend design:

- `skills.frontend-design`

This is the non-pro Xiaomi MIMO model. It is the cheapest model in the current configuration with image input and visual understanding, so use it for any UI, UX, or visual-related work.

<!-- `opencode/deepseek-v4-flash-free` no longer used; commits now use `aihubmix-oc/deep-deepseek-v4-flash` -->

## Maintenance rules

- Keep `skills.frontend-design` on `aihubmix-am/xiaomi-mimo-v2.5` for visual work.
- Keep commit generation on `aihubmix-oc/deep-deepseek-v4-flash` with minimal or no thinking for speed. Use `thinking: minimal` for the ship preset commit stage.
- Keep qwen3.8 reserved for architecture and design work (not blueprint).
- Use `aihubmix-oc/coding-xiaomi-mimo-v2.5-pro` for validation and slice verification.
- Use `aihubmix-am/cc-minimax-m3` for code review, planning, and revise.
- Use `aihubmix-oc/deep-deepseek-v4-flash` for research, implementation, handoffs, and agent support.
