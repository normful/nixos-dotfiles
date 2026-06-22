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
| GLM-5.2 | 880 | 176 | 2.9 |
| GLM-5.1 | 880 | 176 | 2.9 |
| Kimi K2.6 | 1150 | 230 | 3.8 |
| Kimi K2.7 Code | 1350 | 270 | 4.5 |
| MiMo-V2.5 | 30100 | 6020 | 100.3 |
| MiMo-V2.5-Pro | 3250 | 650 | 10.8 |
| MiniMax M3 | 3200 | 640 | 10.7 |
| MiniMax M2.7 | 3400 | 680 | 11.3 |
| Qwen3.7 Max | 950 | 190 | 3.2 |
| Qwen3.7 Plus | 4300 | 860 | 14.3 |
| Qwen3.6 Plus | 3300 | 660 | 11.0 |
| DeepSeek V4 Pro | 3450 | 690 | 11.5 |
| DeepSeek V4 Flash | 31650 | 6330 | 105.5 |

## Model ID Mapping

Display names in the docs vs kebab-case model IDs:

| Display Name | Model ID |
|--------------|----------|
| GLM-5.2 | glm-5.2 |
| GLM-5.1 | glm-5.1 |
| Kimi K2.6 | kimi-k2.6 |
| Kimi K2.7 Code | kimi-k2.7-code |
| MiMo-V2.5 | mimo-v2.5 |
| MiMo-V2.5-Pro | mimo-v2.5-pro |
| MiniMax M3 | minimax-m3 |
| MiniMax M2.7 | minimax-m2.7 |
| Qwen3.7 Max | qwen3.7-max |
| Qwen3.7 Plus | qwen3.7-plus |
| Qwen3.6 Plus | qwen3.6-plus |
| DeepSeek V4 Pro | deepseek-v4-pro |
| DeepSeek V4 Flash | deepseek-v4-flash |

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
    "GLM-5.2": 880,
    "GLM-5.1": 880,
    "Kimi K2.6": 1150,
    "Kimi K2.7 Code": 1350,
    "MiMo-V2.5": 30100,
    "MiMo-V2.5-Pro": 3250,
    "MiniMax M3": 3200,
    "MiniMax M2.7": 3400,
    "Qwen3.7 Max": 950,
    "Qwen3.7 Plus": 4300,
    "Qwen3.6 Plus": 3300,
    "DeepSeek V4 Pro": 3450,
    "DeepSeek V4 Flash": 31650,
}

DISPLAY_TO_ID = {
    "GLM-5.2": "glm-5.2",
    "GLM-5.1": "glm-5.1",
    "Kimi K2.6": "kimi-k2.6",
    "Kimi K2.7 Code": "kimi-k2.7-code",
    "MiMo-V2.5": "mimo-v2.5",
    "MiMo-V2.5-Pro": "mimo-v2.5-pro",
    "MiniMax M3": "minimax-m3",
    "MiniMax M2.7": "minimax-m2.7",
    "Qwen3.7 Max": "qwen3.7-max",
    "Qwen3.7 Plus": "qwen3.7-plus",
    "Qwen3.6 Plus": "qwen3.6-plus",
    "DeepSeek V4 Pro": "deepseek-v4-pro",
    "DeepSeek V4 Flash": "deepseek-v4-flash",
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
