---
name: update-opencode-go-models
description: Update OpenCode Go model rate limits and availability in chezmoi/dot_pi/agent/models.json
---

# Update OpenCode Go Models

> **Document status:** Active

## Overview

Keep `chezmoi/dot_pi/agent/models.json` in sync with OpenCode Go's live model catalog, rate limits, and Artificial Analysis coding index annotations.

**Scope:** Only the `providers.opencode-go.modelOverrides` object. This skill does **not** apply to the `openrouter` provider or the `xai` provider.

## Sources of Truth

| Source | URL | Notes |
|--------|-----|-------|
| Rate limit docs | `gh api repos/anomalyco/opencode/contents/packages/web/src/content/docs/go.mdx --jq '.content' \| base64 -d` | ⚠️ raw.githubusercontent.com truncates output at ~180 lines. Use `gh api` instead. |
| Model IDs | `curl -s https://models.dev/api.json` | jq parsing may fail; save to file first |
| AA coding index | `curl -s https://artificialanalysis.ai/api/v2/data/llms/models -H "x-api-key: $ARTIFICIAL_ANALYSIS_API_KEY" -o /var/tmp/aa.json` | Requires `$ARTIFICIAL_ANALYSIS_API_KEY` to be set. Save to `/var/tmp/aa.json`. |

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

## Analytics Annotation Formula

For models with a non-null AA coding index, append an analytics suffix to the `name` field:

```
<Display Name> (reqs: <N>/hr <M>/min) ⟐  <coding> · ●  <product>k
```

Where:
- `<coding>` = Artificial Analysis Coding Index (1 decimal place, e.g. `68.8`)
- `<product>` = `requests_per_month × coding_index ÷ 1000`, rounded to **nearest integer**, displayed as `k`-suffixed whole number (e.g. `296k`, `8888k`)
- If a model has no AA coding index (null), the analytics suffix is **omitted entirely** — the name stays as the rate-limit-only format

### Examples

| Model | Name field |
|-------|-----------|
| DeepSeek V4 Flash | `DeepSeek V4 Flash (reqs: 6330/hr 105.5/min) ⟐  56.2 · ●  8888k` |
| GLM-5.2 | `GLM-5.2 (reqs: 176/hr 2.9/min) ⟐  68.8 · ●  296k` |
| MiMo-V2.5 | `MiMo-V2.5 (reqs: 6020/hr 100.3/min)` |

## AA Slug Mapping to OpenCode Go Model IDs

AA uses hyphenated slugs. Map from AA slug to OpenCode Go model ID:

| AA Slug | OpenCode Go Model ID |
|---------|---------------------|
| `deepseek-v4-pro` | `deepseek-v4-pro` |
| `deepseek-v4-flash` | `deepseek-v4-flash` |
| `glm-5-2` | `glm-5.2` |
| `glm-5-1` | `glm-5.1` |
| `kimi-k2-7-code` | `kimi-k2.7-code` |
| `kimi-k2-6` | `kimi-k2.6` |
| `mimo-v2-5-pro` | `mimo-v2.5-pro` |
| `mimo-v2-5-0424` | `mimo-v2.5` |
| `minimax-m3` | `minimax-m3` |
| `minimax-m2-7` | `minimax-m2.7` |
| `qwen3-7-max` | `qwen3.7-max` |
| `qwen3-7-plus` | `qwen3.7-plus` |
| `qwen3-6-plus` | `qwen3.6-plus` |

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
┌─────────────────────────────┐
│ 1. Fetch full go.mdx docs   │
│    (use gh api method)      │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│ 2. Fetch AA model data      │
│    (curl → /var/tmp/aa.json)│
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│ 3. Extract rate table       │
│    from "Usage limits"      │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│ 4. Extract AA coding indices│
│    per model slug           │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│ 5. Calculate per-hr/min,    │
│    coding product, build    │
│    name strings             │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│ 6. Compare with current     │
│    JSON and update          │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│ 7. Validate output          │
│    JSON is valid            │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│ 8. Commit                   │
└─────────────────────────────┘
```

## Python Calculation Script

Save to `/tmp/calc_ratelimits.py` and run `python3 /tmp/calc_ratelimits.py`:

```python
#!/usr/bin/env python3
"""Recalculate OpenCode Go model rate limits + analytics from docs and AA data."""

import json

# ── Rate limit + requests-per-month data (from go.mdx) ──────────
MODELS = {
    "GLM-5.2":        {"reqs_5hr": 880,   "reqs_mo": 4300},
    "GLM-5.1":        {"reqs_5hr": 880,   "reqs_mo": 4300},
    "Kimi K2.6":      {"reqs_5hr": 1150,  "reqs_mo": 5750},
    "Kimi K2.7 Code":  {"reqs_5hr": 1350,  "reqs_mo": 9250},
    "MiMo-V2.5":      {"reqs_5hr": 30100, "reqs_mo": 150400},
    "MiMo-V2.5-Pro":  {"reqs_5hr": 3250,  "reqs_mo": 16300},
    "MiniMax M3":     {"reqs_5hr": 3200,  "reqs_mo": 16000},
    "MiniMax M2.7":   {"reqs_5hr": 3400,  "reqs_mo": 17000},
    "Qwen3.7 Max":    {"reqs_5hr": 950,   "reqs_mo": 4770},
    "Qwen3.7 Plus":   {"reqs_5hr": 4300,  "reqs_mo": 21600},
    "Qwen3.6 Plus":   {"reqs_5hr": 3300,  "reqs_mo": 16300},
    "DeepSeek V4 Pro":   {"reqs_5hr": 3450,  "reqs_mo": 17150},
    "DeepSeek V4 Flash": {"reqs_5hr": 31650, "reqs_mo": 158150},
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

# ── AA slug → model ID mapping ─────────────────────────────────
AA_SLUG_TO_MODEL_ID = {
    "deepseek-v4-pro":   "deepseek-v4-pro",
    "deepseek-v4-flash": "deepseek-v4-flash",
    "glm-5-2":          "glm-5.2",
    "glm-5-1":          "glm-5.1",
    "kimi-k2-7-code":   "kimi-k2.7-code",
    "kimi-k2-6":        "kimi-k2.6",
    "mimo-v2-5-pro":    "mimo-v2.5-pro",
    "mimo-v2-5-0424":   "mimo-v2.5",
    "minimax-m3":       "minimax-m3",
    "minimax-m2-7":     "minimax-m2.7",
    "qwen3-7-max":      "qwen3.7-max",
    "qwen3-7-plus":     "qwen3.7-plus",
    "qwen3-6-plus":     "qwen3.6-plus",
}

def load_aa_coding(path="/var/tmp/aa.json"):
    """Load AA coding indices, return dict of model_id → coding or None."""
    with open(path) as f:
        data = json.load(f)
    coding = {}
    for entry in data["data"]:
        aa_slug = entry["slug"]
        if aa_slug in AA_SLUG_TO_MODEL_ID:
            model_id = AA_SLUG_TO_MODEL_ID[aa_slug]
            raw = entry["evaluations"]["artificial_analysis_coding_index"]
            coding[model_id] = round(raw, 1) if raw is not None else None
    return coding

def per_hour(reqs_5hr):
    return round(reqs_5hr / 5)

def per_minute(reqs_5hr):
    return round(reqs_5hr / 5 / 60, 1)

def product_k(reqs_mo, coding):
    """req×coding ÷ 1000, rounded to nearest integer."""
    if coding is None:
        return None
    return round(reqs_mo * coding / 1000)

def full_name(display_name, reqs_5hr, reqs_mo, coding):
    """Build the full name string with rate limits and optional analytics suffix."""
    pH = per_hour(reqs_5hr)
    pM = per_minute(reqs_5hr)
    base = f"{display_name} (reqs: {pH}/hr {pM}/min)"
    if coding is not None:
        pk = product_k(reqs_mo, coding)
        return f"{base} \u27d0  {coding} \u00b7 \u25cf  {pk}k"
    return base

def main():
    aa_coding = load_aa_coding()

    print("Model ID | Display Name | Reqs/5hr | Per Hour | Per Min | Coding | Product(k)")
    print("---------|--------------|----------|----------|---------|--------|------------")
    for display_name, data in sorted(MODELS.items()):
        model_id = DISPLAY_TO_ID[display_name]
        coding = aa_coding.get(model_id)
        pH = per_hour(data["reqs_5hr"])
        pM = per_minute(data["reqs_5hr"])
        pk = product_k(data["reqs_mo"], coding)
        coding_str = str(coding) if coding is not None else "N/A"
        pk_str = str(pk) if pk is not None else "N/A"
        print(f'"{model_id}": {{"name": "{full_name(display_name, data["reqs_5hr"], data["reqs_mo"], coding)}"}}')
        print(f"  Rate: {data['reqs_5hr']}/5hr → {pH}/hr {pM}/min | AA: {coding_str} | xP: {pk_str}k")

    print("\n--- JSON snippet ---")
    entries = []
    for display_name, data in sorted(MODELS.items()):
        model_id = DISPLAY_TO_ID[display_name]
        coding = aa_coding.get(model_id)
        entries.append(f'        "{model_id}": {{"name": "{full_name(display_name, data["reqs_5hr"], data["reqs_mo"], coding)}"}}')

    print('"opencode-go": {\n      "modelOverrides": {\n' + ",\n".join(entries) + "\n      }\n    },")

if __name__ == "__main__":
    main()
```

## Common Mistakes to Avoid

1. **Fetching truncated docs**: `curl https://raw.githubusercontent.com/...` returns ~32 lines. Use `gh api ... | base64 -d` to get the full 178 lines.

2. **Wrong per-minute calculation**: Per-minute is `reqs_5hr / 5 / 60`, NOT `per_hour / 60`. Calculate both values from the original `requests per 5 hours` value.

3. **Swapped rate limits**: Verify that the cheaper model (Qwen3.5 Plus) has MORE requests/hr than the expensive one (Qwen3.6 Plus). Qwen3.5 Plus should be ~2040/hr, Qwen3.6 Plus should be ~660/hr.

4. **Inconsistent naming**: Use exact display names from docs (e.g., `GLM-5.1` not `GLM 5.1`).

5. **Missing AA data fetch**: If AA API returns an error or empty data, skip the analytics suffix for all models rather than failing. Log the error, proceed with rate-limit-only names.

6. **Stale AA data in cache**: Always re-fetch `/var/tmp/aa.json` each run. Do not reuse a cached copy.

7. **Wrong AA slug**: AA slugs use hyphens (e.g. `glm-5-2`, `mimo-v2-5-0424`), while OpenCode Go model IDs use dots (e.g. `glm-5.2`). The `AA_SLUG_TO_MODEL_ID` mapping handles this — do not attempt to derive one from the other algorithmically.
