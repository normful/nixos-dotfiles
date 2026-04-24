---
name: update-opencode-go-models
description: Update OpenCode Go model rate limits and availability in chezmoi/dot_pi/agent/models.json
---

# Update OpenCode Go Models

> **Document status:** Active

## Overview

Keep `chezmoi/dot_pi/agent/models.json` in sync with OpenCode Go's live model catalog and rate limits.

**Scope:** Only the `providers.opencode-go.modelOverrides` object. This skill does **not** apply to the `openrouter` provider or the `xai` provider.

## Sources of Truth

| Source | URL | Notes |
|--------|-----|-------|
| Rate limit docs | `gh api repos/anomalyco/opencode/contents/packages/web/src/content/docs/go.mdx --jq '.content' \| base64 -d` | ⚠️ raw.githubusercontent.com truncates output at ~180 lines. Use `gh api` instead. |
| Model IDs | `curl -s https://models.dev/api.json` | jq parsing may fail; save to file first |

## Target file to modify

`chezmoi/dot_pi/agent/models.json` — the `providers.opencode-go.modelOverrides` object.

## Rate Limit Formula

All `name` fields must follow this exact pattern:

```
<Display Name> (reqs: <N>/hr <M>/min)
```

Where:
- `<N>` = requests per 5 hours ÷ 5 (round to **nearest integer**)
- `<M>` = requests per 5 hours ÷ 5 ÷ 60 (round to **1 decimal place**)

⚠️ **Common mistake**: Do NOT calculate per-minute as `<N> ÷ 60`. Calculate both per-hour and per-minute from the original `requests per 5 hours` value.

## Rate Limit Reference Table

Extract from go.mdx section "Usage limits". Use these values for calculations:

| Model | Requests per 5hr | Per Hour (÷5) | Per Min (÷5÷60) |
|-------|-----------------|---------------|-----------------|
| GLM-5.1 | 880 | 176 | 2.9 |
| GLM-5 | 1150 | 230 | 3.8 |
| Kimi K2.5 | 1850 | 370 | 6.2 |
| Kimi K2.6 | 1150 | 230 | 3.8 |
| MiMo-V2-Pro | 1290 | 258 | 4.3 |
| MiMo-V2-Omni | 2150 | 430 | 7.2 |
| MiMo-V2.5-Pro | 1290 | 258 | 4.3 |
| MiMo-V2.5 | 2150 | 430 | 7.2 |
| Qwen3.6 Plus | 3300 | 660 | 11.0 |
| MiniMax M2.7 | 3400 | 680 | 11.3 |
| MiniMax M2.5 | 6300 | 1260 | 21.0 |
| Qwen3.5 Plus | 10200 | 2040 | 34.0 |

## Model ID Mapping

Display names in the docs vs kebab-case model IDs:

| Display Name | Model ID |
|--------------|----------|
| GLM-5.1 | glm-5.1 |
| GLM-5 | glm-5 |
| Kimi K2.5 | kimi-k2.5 |
| Kimi K2.6 | kimi-k2.6 |
| MiMo-V2-Pro | mimo-v2-pro |
| MiMo-V2-Omni | mimo-v2-omni |
| MiMo-V2.5-Pro | mimo-v2.5-pro |
| MiMo-V2.5 | mimo-v2.5 |
| Qwen3.6 Plus | qwen3.6-plus |
| MiniMax M2.7 | minimax-m2.7 |
| MiniMax M2.5 | minimax-m2.5 |
| Qwen3.5 Plus | qwen3.5-plus |

## Process

```
┌─────────────────────────┐
│ 1. Fetch full docs      │
│    (use gh api method)  │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ 2. Extract rate table   │
│    from "Usage limits"  │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ 3. Calculate per-hr/min │
│    using Python script   │
│    (see below)          │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ 4. Compare with current │
│    JSON and update      │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ 5. Validate output      │
│    JSON is valid        │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ 6. Commit               │
└─────────────────────────┘
```

## Python Calculation Script

Save to `/tmp/calc_ratelimits.py` and run `python3 /tmp/calc_ratelimits.py`:

```python
#!/usr/bin/env python3
"""Recalculate OpenCode Go model rate limits from docs data."""

MODELS = {
    "GLM-5.1": 880,
    "GLM-5": 1150,
    "Kimi K2.5": 1850,
    "Kimi K2.6": 1150,
    "MiMo-V2-Pro": 1290,
    "MiMo-V2-Omni": 2150,
    "MiMo-V2.5-Pro": 1290,
    "MiMo-V2.5": 2150,
    "Qwen3.6 Plus": 3300,
    "MiniMax M2.7": 3400,
    "MiniMax M2.5": 6300,
    "Qwen3.5 Plus": 10200,
}

DISPLAY_TO_ID = {
    "GLM-5.1": "glm-5.1",
    "GLM-5": "glm-5",
    "Kimi K2.5": "kimi-k2.5",
    "Kimi K2.6": "kimi-k2.6",
    "MiMo-V2-Pro": "mimo-v2-pro",
    "MiMo-V2-Omni": "mimo-v2-omni",
    "MiMo-V2.5-Pro": "mimo-v2.5-pro",
    "MiMo-V2.5": "mimo-v2.5",
    "Qwen3.6 Plus": "qwen3.6-plus",
    "MiniMax M2.7": "minimax-m2.7",
    "MiniMax M2.5": "minimax-m2.5",
    "Qwen3.5 Plus": "qwen3.5-plus",
}

def per_hour(reqs_5hr):
    return round(reqs_5hr / 5)

def per_minute(reqs_5hr):
    return round(reqs_5hr / 5 / 60, 1)

print("Model ID | Display Name | Reqs/5hr | Per Hour | Per Min")
print("---------|--------------|----------|----------|--------")
for display_name, reqs_5hr in sorted(MODELS.items()):
    model_id = DISPLAY_TO_ID[display_name]
    pH = per_hour(reqs_5hr)
    pM = per_minute(reqs_5hr)
    print(f'"{model_id}": {{"name": "{display_name} (reqs: {pH}/hr {pM}/min)"}},')

print("\n--- JSON snippet ---")
entries = []
for display_name, reqs_5hr in sorted(MODELS.items()):
    model_id = DISPLAY_TO_ID[display_name]
    pH = per_hour(reqs_5hr)
    pM = per_minute(reqs_5hr)
    entries.append(f'        "{model_id}": {{"name": "{display_name} (reqs: {pH}/hr {pM}/min)"}}')

print('"opencode-go": {\n      "modelOverrides": {\n' + ",\n".join(entries) + "\n      }\n    },")
```

## Common Mistakes to Avoid

1. **Fetching truncated docs**: `curl https://raw.githubusercontent.com/...` returns ~32 lines. Use `gh api ... | base64 -d` to get the full 178 lines.

2. **Wrong per-minute calculation**: Per-minute is `reqs_5hr / 5 / 60`, NOT `per_hour / 60`. Calculate both values from the original `requests per 5 hours` value.

3. **Swapped rate limits**: Verify that the cheaper model (Qwen3.5 Plus) has MORE requests/hr than the expensive one (Qwen3.6 Plus). Qwen3.5 Plus should be ~2040/hr, Qwen3.6 Plus should be ~660/hr.

4. **Inconsistent naming**: Use exact display names from docs (e.g., `GLM-5.1` not `GLM 5.1`).
