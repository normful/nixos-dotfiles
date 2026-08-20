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
| AA coding index | `curl -s https://artificialanalysis.ai/api/v2/data/llms/models -H "x-api-key: [REDACTED:API key param]" -o /var/tmp/aa.json` | Requires `$ARTIFICIAL_ANALYSIS_API_KEY` to be set. Save to `/var/tmp/aa.json`. |

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
| DeepSeek V4 Flash | `DeepSeek V4 Flash (reqs: 1520/hr 25.3/min) ⟐  69.1 · ●  2612k` |
| GLM-5.2 | `GLM-5.2 (reqs: 176/hr 2.9/min) ⟐  68.8 · ●  296k` |
| Muse Spark 1.2 Contributor | `Muse Spark 1.2 Contributor (reqs: 9060/hr 151.0/min) ⟐  72.2 · ●  16361k` |

## AA Slug Mapping to OpenCode Go Model IDs

AA uses hyphenated slugs. Map from AA slug to OpenCode Go model ID. For models with multiple effort variants, pick **high → xhigh → max** priority (high if AA has it, else xhigh, else max):

| AA Slug | OpenCode Go Model ID | Effort |
| `deepseek-v4-pro-0424-high` | `deepseek-v4-pro` | high (fallback to `deepseek-v4-pro` max) |
| `deepseek-v4-pro` | `deepseek-v4-pro` | max |
| `deepseek-v4-flash` | `deepseek-v4-flash` | max |
| `glm-5-3` | `glm-5.3` | — |
| `glm-5-2` | `glm-5.2` | — |
| `glm-5-1` | `glm-5.1` | — |
| `grok-4-5` | `grok-4.5` | high |
| `gpt-5-6-luna-high` | `gpt-5.6-luna` | high (fallback `gpt-5-6-luna-xhigh` → `gpt-5-6-luna` max) |
| `gpt-5-6-luna-xhigh` | `gpt-5.6-luna` | xhigh |
| `gpt-5-6-luna` | `gpt-5.6-luna` | max |
| `kimi-k3` | `kimi-k3` | max |
| `kimi-k2-7-code` | `kimi-k2.7-code` | — |
| `kimi-k2-6` | `kimi-k2.6` | — |
| `mimo-v2-5-pro` | `mimo-v2.5-pro` | — |
| `mimo-v2-5-0424` | `mimo-v2.5` | — (MiMo-V2.5 is distinct from MiMo-V2.5-Pro) |
| `minimax-m3` | `minimax-m3` | — |
| `minimax-m2-7` | `minimax-m2.7` | — |
| `muse-spark-1-2` | `muse-spark-1.2` | xhigh |
| `qwen3-8-max` | `qwen3.8-max` | — |
| `qwen3-7-max` | `qwen3.7-max` | — |
| `qwen3-7-plus` | `qwen3.7-plus` | — |
| `qwen3-6-plus` | `qwen3.6-plus` | — |
| `hy3` | `hy3` | — |

## Rate Limit Reference Table

Extract from go.mdx section "Usage limits". Use these values for calculations (20 models as of 2026-08-20):

| Model | Requests per 5hr | Requests per month | Per Hour (÷5) | Per Min (÷5÷60) |
| Grok 4.5 | 120 | 600 | 24 | 0.4 |
| GPT 5.6 Luna | 2050 | 10250 | 410 | 6.8 |
| GLM-5.3 | 220 | 1080 | 44 | 0.7 |
| GLM-5.2 | 880 | 4300 | 176 | 2.9 |
| GLM-5.1 | 880 | 4300 | 176 | 2.9 |
| Kimi K3 | 110 | 490 | 22 | 0.4 |
| Kimi K2.7 Code | 1350 | 6750 | 270 | 4.5 |
| Kimi K2.6 | 1150 | 5750 | 230 | 3.8 |
| MiMo-V2.5 | 30100 | 150400 | 6020 | 100.3 |
| MiMo-V2.5-Pro | 3250 | 16300 | 650 | 10.8 |
| MiniMax M3 | 3200 | 16000 | 640 | 10.7 |
| MiniMax M2.7 | 3400 | 17000 | 680 | 11.3 |
| Muse Spark 1.2 Contributor | 45300 | 226600 | 9060 | 151.0 |
| Qwen3.8 Max | 160 | 810 | 32 | 0.5 |
| Qwen3.7 Max | 340 | 1690 | 68 | 1.1 |
| Qwen3.7 Plus | 4300 | 21600 | 860 | 14.3 |
| Qwen3.6 Plus | 3300 | 16300 | 660 | 11.0 |
| DeepSeek V4 Pro | 1050 | 5200 | 210 | 3.5 |
| DeepSeek V4 Flash | 7600 | 37800 | 1520 | 25.3 |
| Hy3 | 4300 | 21500 | 860 | 14.3 |

## Model ID Mapping

Display names in the docs vs kebab-case model IDs (display name is what appears in `modelOverrides[].name` before the rate suffix):

| Display Name | Model ID |
| Grok 4.5 | grok-4.5 |
| GPT 5.6 Luna | gpt-5.6-luna |
| GLM-5.3 | glm-5.3 |
| GLM-5.2 | glm-5.2 |
| GLM-5.1 | glm-5.1 |
| Kimi K3 | kimi-k3 |
| Kimi K2.6 | kimi-k2.6 |
| Kimi K2.7 Code | kimi-k2.7-code |
| MiMo-V2.5 | mimo-v2.5 |
| MiMo-V2.5-Pro | mimo-v2.5-pro |
| MiniMax M3 | minimax-m3 |
| MiniMax M2.7 | minimax-m2.7 |
| Muse Spark 1.2 Contributor | muse-spark-1.2 |
| Qwen3.8 Max | qwen3.8-max |
| Qwen3.7 Max | qwen3.7-max |
| Qwen3.7 Plus | qwen3.7-plus |
| Qwen3.6 Plus | qwen3.6-plus |
| DeepSeek V4 Pro | deepseek-v4-pro |
| DeepSeek V4 Flash | deepseek-v4-flash |
| Hy3 | hy3 |

## Process

```
│ 1. Fetch full go.mdx docs   │
│    (use gh api method)      │
             │
             ▼
│ 2. Fetch AA model data      │
│    (curl → /var/tmp/aa.json)│
             │
             ▼
│ 3. Extract rate table       │
│    from "Usage limits"      │
│    (verify row count == expected 20) │
             │
             ▼
│ 4. Extract AA coding indices│
│    per model slug           │
             │
             ▼
│ 5. Calculate per-hr/min,    │
│    coding product, build    │
│    name strings             │
             │
             ▼
│ 6. Compare with current     │
│    JSON and update          │
             │
             ▼
│ 7. Validate output          │
│    JSON is valid            │
             │
             ▼
│ 8. Commit                   │
```

## Python Calculation Script

Save to `/tmp/calc_ratelimits.py` and run `python3 /tmp/calc_ratelimits.py`:

```python
#!/usr/bin/env python3
"""Recalculate OpenCode Go model rate limits + analytics from docs and AA data."""

import json

MODELS = {
    "Grok 4.5":          {"reqs_5hr": 120,   "reqs_mo": 600},
    "GPT 5.6 Luna":      {"reqs_5hr": 2050,  "reqs_mo": 10250},
    "GLM-5.3":           {"reqs_5hr": 220,   "reqs_mo": 1080},
    "GLM-5.2":           {"reqs_5hr": 880,   "reqs_mo": 4300},
    "GLM-5.1":           {"reqs_5hr": 880,   "reqs_mo": 4300},
    "Kimi K3":           {"reqs_5hr": 110,   "reqs_mo": 490},
    "Kimi K2.7 Code":    {"reqs_5hr": 1350,  "reqs_mo": 6750},
    "Kimi K2.6":         {"reqs_5hr": 1150,  "reqs_mo": 5750},
    "MiMo-V2.5":         {"reqs_5hr": 30100, "reqs_mo": 150400},
    "MiMo-V2.5-Pro":     {"reqs_5hr": 3250,  "reqs_mo": 16300},
    "MiniMax M3":        {"reqs_5hr": 3200,  "reqs_mo": 16000},
    "MiniMax M2.7":      {"reqs_5hr": 3400,  "reqs_mo": 17000},
    "Muse Spark 1.2 Contributor": {"reqs_5hr": 45300, "reqs_mo": 226600},
    "Qwen3.8 Max":       {"reqs_5hr": 160,   "reqs_mo": 810},
    "Qwen3.7 Max":       {"reqs_5hr": 340,   "reqs_mo": 1690},
    "Qwen3.7 Plus":      {"reqs_5hr": 4300,  "reqs_mo": 21600},
    "Qwen3.6 Plus":      {"reqs_5hr": 3300,  "reqs_mo": 16300},
    "DeepSeek V4 Pro":   {"reqs_5hr": 1050,  "reqs_mo": 5200},
    "DeepSeek V4 Flash": {"reqs_5hr": 7600,  "reqs_mo": 37800},
    "Hy3":               {"reqs_5hr": 4300,  "reqs_mo": 21500},
}

DISPLAY_TO_ID = {
    "Grok 4.5": "grok-4.5",
    "GPT 5.6 Luna": "gpt-5.6-luna",
    "GLM-5.3": "glm-5.3",
    "GLM-5.2": "glm-5.2",
    "GLM-5.1": "glm-5.1",
    "Kimi K3": "kimi-k3",
    "Kimi K2.6": "kimi-k2.6",
    "Kimi K2.7 Code": "kimi-k2.7-code",
    "MiMo-V2.5": "mimo-v2.5",
    "MiMo-V2.5-Pro": "mimo-v2.5-pro",
    "MiniMax M3": "minimax-m3",
    "MiniMax M2.7": "minimax-m2.7",
    "Muse Spark 1.2 Contributor": "muse-spark-1.2",
    "Qwen3.8 Max": "qwen3.8-max",
    "Qwen3.7 Max": "qwen3.7-max",
    "Qwen3.7 Plus": "qwen3.7-plus",
    "Qwen3.6 Plus": "qwen3.6-plus",
    "DeepSeek V4 Pro": "deepseek-v4-pro",
    "DeepSeek V4 Flash": "deepseek-v4-flash",
    "Hy3": "hy3",
}

AA_SLUG_TO_MODEL_ID = {
    "grok-4-5":                "grok-4.5",
    "gpt-5-6-luna-high":       "gpt-5.6-luna",
    "gpt-5-6-luna-xhigh":      "gpt-5.6-luna",
    "gpt-5-6-luna":            "gpt-5.6-luna",
    "glm-5-3":                 "glm-5.3",
    "glm-5-2":                 "glm-5.2",
    "glm-5-1":                 "glm-5.1",
    "kimi-k3":                 "kimi-k3",
    "kimi-k2-7-code":          "kimi-k2.7-code",
    "kimi-k2-6":               "kimi-k2.6",
    "mimo-v2-5-pro":           "mimo-v2.5-pro",
    "mimo-v2-5-0424":          "mimo-v2.5",
    "minimax-m3":              "minimax-m3",
    "minimax-m2-7":            "minimax-m2.7",
    "muse-spark-1-2":          "muse-spark-1.2",
    "qwen3-8-max":             "qwen3.8-max",
    "qwen3-7-max":             "qwen3.7-max",
    "qwen3-7-plus":            "qwen3.7-plus",
    "qwen3-6-plus":            "qwen3.6-plus",
    "deepseek-v4-pro-0424-high": "deepseek-v4-pro",
    "deepseek-v4-pro":         "deepseek-v4-pro",
    "deepseek-v4-flash":       "deepseek-v4-flash",
    "hy3":                     "hy3",
}

# Priority for models with multiple effort variants: high → xhigh → max
AA_PRIORITY = {
    "gpt-5.6-luna":    ["gpt-5-6-luna-high", "gpt-5-6-luna-xhigh", "gpt-5-6-luna"],
    "deepseek-v4-pro": ["deepseek-v4-pro-0424-high", "deepseek-v4-pro"],
}

def load_aa_coding(path="/var/tmp/aa.json"):
    """Load AA coding indices, return dict of model_id → coding or None."""
    with open(path) as f:
        data = json.load(f)
    # slug → entry
    by_slug = {e["slug"]: e for e in data["data"]}
    coding = {}
    for model_id in set(AA_SLUG_TO_MODEL_ID.values()):
        # check if this model has priority list
        candidates = AA_PRIORITY.get(model_id)
        if candidates:
            for slug in candidates:
                ent = by_slug.get(slug)
                if ent is not None:
                    raw = ent["evaluations"]["artificial_analysis_coding_index"]
                    if raw is not None:
                        coding[model_id] = round(raw, 1)
                        break
            else:
                # no candidate had non-null coding
                coding[model_id] = None
        else:
            # single slug models — find the slug(s) mapping to this model
            slugs = [s for s, m in AA_SLUG_TO_MODEL_ID.items() if m == model_id]
            # should be one
            ent = by_slug.get(slugs[0]) if slugs else None
            if ent is not None:
                raw = ent["evaluations"]["artificial_analysis_coding_index"]
                coding[model_id] = round(raw, 1) if raw is not None else None
            else:
                coding[model_id] = None
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

1. **Fetching truncated docs**: `curl https://raw.githubusercontent.com/...` returns ~32 lines. Use `gh api ... | base64 -d` to get the full 288 lines.

2. **Wrong per-minute calculation**: Per-minute is `reqs_5hr / 5 / 60`, NOT `per_hour / 60`. Calculate both values from the original `requests per 5 hours` value.

3. **Swapped rate limits**: Verify cheaper models have MORE requests/hr than expensive ones. For example Qwen3.7 Plus should be ~860/hr while Qwen3.7 Max is ~68/hr, and Qwen3.6 Plus ~660/hr vs Qwen3.8 Max ~32/hr. If you see the expensive Max with higher limits, you swapped rows.

4. **Inconsistent naming**: Use exact display names from docs verbatim (e.g., `GLM-5.3` not `GLM 5.3`, `GPT 5.6 Luna` not `GPT-5.6-Luna`, `Muse Spark 1.2 Contributor` not `Muse Spark 1.2`). MiMo-V2.5 and MiMo-V2.5-Pro are distinct models — do not conflate them.

5. **Missing AA data fetch**: If AA API returns an error or empty data, skip the analytics suffix for all models rather than failing. Log the error, proceed with rate-limit-only names.

6. **Stale AA data in cache**: Always re-fetch `/var/tmp/aa.json` each run. Do not reuse a cached copy.

7. **Wrong AA slug**: AA slugs use hyphens (e.g. `glm-5-2`, `mimo-v2-5-0424`, `muse-spark-1-2`), while OpenCode Go model IDs use dots (e.g. `glm-5.2`). The `AA_SLUG_TO_MODEL_ID` mapping handles this — do not attempt to derive one from the other algorithmically.

8. **Missing new models**: The catalog now has 20 models (not 13). If `go.mdx` row count ≠ `len(MODELS)`, update the skill — do not silently drop new models like `grok-4.5`, `glm-5.3`, `kimi-k3`, `muse-spark-1.2`, `qwen3.8-max`, `gpt-5.6-luna`, `hy3`.

9. **Trailing commas / invalid JSON**: `chezmoi/dot_pi/agent/models.json` must be strict JSON (no trailing commas). Validate with `python3 -m json.tool` or `jq` — previously the file had trailing commas and failed both.
