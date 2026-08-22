---
name: maintain-rpiv-pi-models
description: Maintain models used for rpiv-pi skills and agents
modified: 2026-08-05T15:30:37+0900
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
| Planning / code review / revise | `aihubmix-am/cc-minimax-m3` |
| Validation / slice verification | `opencode-go/mimo-v2.5-pro` |
| Blueprint | `opencode-go/muse-spark-1.2-contributor` |
| Architecture / design | `opencode-go/muse-spark-1.2-contributor` |
| Claim verification | `opencode-go/mimo-v2.5-pro` |
| Commit generation | `opencode-go/muse-spark-1.2-contributor` (ship preset: `thinking: minimal`) |
| Visual/frontend design | `opencode-go/deepseek-v4-flash-vision-exp` |

## Low-hallucination models

Use `aihubmix-am/cc-minimax-m3` and `opencode-go/mimo-v2.5-pro` for tasks requiring rigid adherence to instructions. Both have low hallucination rates, so they are good choices when the model must follow constraints, preserve facts, and avoid inventing details.

- `aihubmix-am/cc-minimax-m3`: planning, code review, and revise
- `opencode-go/mimo-v2.5-pro`: validation, slice verification, and claim verification

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
- `presets.build.stages.validate`
- `presets.ship.stages.validate`

### `aihubmix-am/cc-minimax-m3`

Use for planning, code review, and revision:

- `stages.code-review`
- `skills.code-review`
- `skills.plan`
- `presets.build.stages.code-review`
- `presets.build.stages.revise`

### `opencode-go/deepseek-v4-flash-vision-exp`

Use for visual/frontend design:

- `skills.frontend-design`

This is a vision-capable flash model with image input and visual understanding, so use it for any UI, UX, or visual-related work.

<!-- `openrouter/nex-agi/nex-n2-mini` no longer used; discover/explore now use `opencode-go/muse-spark-1.2-contributor` -->
<!-- `aihubmix-oc/qwen3.8-max-preview` no longer used; architecture/design now use `opencode-go/muse-spark-1.2-contributor` -->

## Maintenance rules

- Keep `skills.frontend-design` on `opencode-go/deepseek-v4-flash-vision-exp` for visual work.
- Keep commit generation on `opencode-go/muse-spark-1.2-contributor` with minimal or no thinking for speed. Use `thinking: minimal` for the ship preset commit stage.
- Use `opencode-go/mimo-v2.5-pro` for validation, slice verification, and claim verification.
- Use `aihubmix-am/cc-minimax-m3` for code review, planning, and revise.
- Use `opencode-go/muse-spark-1.2-contributor` for research, implementation, handoffs, blueprint, architecture/design, and agent support.