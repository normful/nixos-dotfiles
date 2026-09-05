---
name: update-pi-model-overrides
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
| Rate limit docs (opencode-go) | `gh api repos/anomalyco/opencode/contents/packages/web/src/content/docs/go.mdx --jq '.content' \| base64 -d` | ⚠️ raw.githubusercontent.com truncates output at ~180 lines. Use `gh api` instead. |
| AA coding index | `curl -s https://artificialanalysis.ai/api/v2/data/llms/models -H "x-api-key: [REDACTED:API key param]" -o /var/tmp/aa.json` | Requires `$ARTIFICIAL_ANALYSIS_API_KEY` to be set. Save to `/var/tmp/aa.json`. |
| AihubMix pricing (for `aihubmix-*` enabledModels) | `curl -s https://aihubmix.com/api/v1/models?type=llm -o /tmp/aihubmix.json` | No auth. `jq` by `model_id`. Fields `pricing.input/output/cache_read`. |
| OpenRouter pricing (for `openrouter/*` enabledModels) | `curl -s https://models.dev/api.json -o /tmp/models_dev.json` | Parse `openrouter.models[\"<model-id>\"].cost`. |
| Enabled models list | `chezmoi/dot_pi/agent/settings.json` key `enabledModels` | order in file **kept as-is** — only `modelOverrides` objects are sorted descending by `⟐`. |

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
| DeepSeek V4 Flash | `DeepSeek V4 Flash (reqs: 1520/hr 25.3/min) ⟐  69.1 · ●  2,612k` |
| GLM-5.2 | `GLM-5.2 (reqs: 176/hr 2.9/min) ⟐  68.8 · ●  296k` |
| Muse Spark 1.2 Contributor | `Muse Spark 1.2 Contributor (reqs: 9060/hr 151.0/min) ⟐  72.2 · ●  16,361k` |

### Ordering

Entries in `providers.opencode-go.modelOverrides` **must be written top-to-bottom in descending order of `⟐` (AA coding index) value** — highest coding first, `null` (no suffix) last. On ties, sort alphabetically by display name ascending. E.g. `Grok 4.6 (76.8)` → `Muse Spark 1.3 (76.3)` → `Kimi K3 (76.2)` → … → `LongCat-2.0 (45.3)` → nulls last.

## AA Slug Mapping to OpenCode Go Model IDs

AA uses hyphenated slugs. Map from AA slug to OpenCode Go model ID. For models with multiple effort variants, pick **high → xhigh → max** priority (high if AA has it, else xhigh, else max):

| AA Slug | OpenCode Go Model ID | Effort |
| `grok-4-6` | `grok-4.6` | high |
| `deepseek-v4-pro` | `deepseek-v4-pro` | **0813 Max — 68.8 coding / 53.2 intel / $1.98 blended ($1.32 in / $3.96 out) 75.2 tps** — canonical for DeepSeek V4 Pro |
| `deepseek-v4-flash` | `deepseek-v4-flash` | **0731 Max — 69.1 coding / 51.8 intel / $0.66 blended ($0.44 in / $1.32 out) 114.6 tps** — canonical for DeepSeek V4 Flash |
| `deepseek-v4-flash-vision` | `deepseek-v4-flash-vision-exp` | fallback (no `deepseek-v4-flash-vision-exp` slug in AA; vision max = 65) |
| `glm-5-3-flash` | `glm-5.3-flash` | — |
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
| `longcat-2-0` | `longcat-2.0` | — |
| `mimo-v2-5-pro` | `mimo-v2.5-pro` | — |
| `mimo-v2-5-0424` | `mimo-v2.5` | — (MiMo-V2.5 is distinct from MiMo-V2.5-Pro) |
| `minimax-m3` | `minimax-m3` | — |
| `minimax-m2-7` | `minimax-m2.7` | — |
| `minimax-m2-5` | `minimax-m2.5` | — (AA coding null → omit suffix) |
| `muse-spark-1-3` | `muse-spark-1.3-contributor` (+ bare `muse-spark-1.3` alias, same rates/coding) | max |
| `muse-spark-1-2` | `muse-spark-1.2-contributor` (+ bare `muse-spark-1.2` alias, same rates/coding) | xhigh |
| `qwen3-8-max` | `qwen3.8-max` | — |
| `qwen3-8-flash-next` | `qwen3.8-flash` | fallback (no `qwen3-8-flash` slug in AA) |
| `qwen3-7-max` | `qwen3.7-max` | — |
| `qwen3-7-plus` | `qwen3.7-plus` | — |
| `qwen3-6-plus` | `qwen3.6-plus` | — |
| `hy3` | `hy3` | — |
| *(no AA slug)* | `hy4-preview`, `omen-alpha` | — (AA null/missing → rate-limit-only name) |

> **DeepSeek canonical (override — use this data specifically):**
> | AA Slug | Name | Release | Coding | Intelligence | AA Pricing (blended / in / out) | Median tps |
> | `deepseek-v4-pro` | DeepSeek V4 Pro **0813** (Reasoning, Max) | 2026-08-13 | **68.8** | **53.2** | $1.98 / $1.32 / $3.96 | 75.2 |
> | `deepseek-v4-flash` | DeepSeek V4 Flash **0731** (Reasoning, Max) | 2026-07-31 | **69.1** | **51.8** | $0.66 / $0.44 / $1.32 | 114.6 |

## Rate Limit Reference Table

Extract from go.mdx section "Usage limits". Use these values for calculations (27 models as of 2026-09-05):

| Model | Requests per 5hr | Requests per month | Per Hour (÷5) | Per Min (÷5÷60) |
| Grok 4.6 | 169 | 845 | 34 | 0.6 |
| GPT 5.6 Luna | 2050 | 10250 | 410 | 6.8 |
| GLM-5.3-Flash | 1580 | 7900 | 316 | 5.3 |
| GLM-5.3 | 220 | 1080 | 44 | 0.7 |
| GLM-5.2 | 880 | 4300 | 176 | 2.9 |
| GLM-5.1 | 880 | 4300 | 176 | 2.9 |
| Kimi K3 | 110 | 490 | 22 | 0.4 |
| Kimi K2.7 Code | 1350 | 6750 | 270 | 4.5 |
| Kimi K2.6 | 1150 | 5750 | 230 | 3.8 |
| LongCat-2.0 | 11400 | 57200 | 2280 | 38.0 |
| MiMo-V2.5 | 30100 | 150400 | 6020 | 100.3 |
| MiMo-V2.5-Pro | 3250 | 16300 | 650 | 10.8 |
| MiniMax M3 | 3200 | 16000 | 640 | 10.7 |
| MiniMax M2.7 | 3400 | 17000 | 680 | 11.3 |
| Muse Spark 1.3 Contributor | 45300 | 226600 | 9060 | 151.0 |
| Muse Spark 1.2 Contributor | 45300 | 226600 | 9060 | 151.0 |
| Qwen3.8 Max | 160 | 810 | 32 | 0.5 |
| Qwen3.8 Flash | 5400 | 27000 | 1080 | 18.0 |
| Qwen3.7 Max | 170 | 840 | 34 | 0.6 |
| Qwen3.7 Plus | 4300 | 21600 | 860 | 14.3 |
| Qwen3.6 Plus | 3300 | 16300 | 660 | 11.0 |
| DeepSeek V4 Pro | 1050 | 5200 | 210 | 3.5 |
| DeepSeek V4 Flash | 7600 | 37800 | 1520 | 25.3 |
| DeepSeek V4 Flash Vision Exp | 3800 | 18900 | 760 | 12.7 |
| Hy4 preview | 1350 | 6770 | 270 | 4.5 |
| Hy3 | 4300 | 21500 | 860 | 14.3 |
| Omen Alpha | 11600 | 57900 | 2320 | 38.7 |

## Model ID Mapping

Display names in the docs vs kebab-case model IDs (display name is what appears in `modelOverrides[].name` before the rate suffix):

| Display Name | Model ID |
| Grok 4.6 | grok-4.6 |
| GPT 5.6 Luna | gpt-5.6-luna |
| GLM-5.3-Flash | glm-5.3-flash |
| GLM-5.3 | glm-5.3 |
| GLM-5.2 | glm-5.2 |
| GLM-5.1 | glm-5.1 |
| Kimi K3 | kimi-k3 |
| Kimi K2.6 | kimi-k2.6 |
| Kimi K2.7 Code | kimi-k2.7-code |
| LongCat-2.0 | longcat-2.0 |
| MiMo-V2.5 | mimo-v2.5 |
| MiMo-V2.5-Pro | mimo-v2.5-pro |
| MiniMax M3 | minimax-m3 |
| MiniMax M2.7 | minimax-m2.7 |
| Muse Spark 1.3 Contributor | muse-spark-1.3-contributor (bare `muse-spark-1.3` alias shares rates/coding) |
| Muse Spark 1.2 Contributor | muse-spark-1.2-contributor (bare `muse-spark-1.2` alias shares rates/coding) |
| Qwen3.8 Max | qwen3.8-max |
| Qwen3.8 Flash | qwen3.8-flash |
| Qwen3.7 Max | qwen3.7-max |
| Qwen3.7 Plus | qwen3.7-plus |
| Qwen3.6 Plus | qwen3.6-plus |
| DeepSeek V4 Pro | deepseek-v4-pro |
| DeepSeek V4 Flash | deepseek-v4-flash |
| DeepSeek V4 Flash Vision Exp | deepseek-v4-flash-vision-exp |
| Hy4 preview | hy4-preview |
| Hy3 | hy3 |
| Omen Alpha | omen-alpha |

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
    "Grok 4.6":          {"reqs_5hr": 169,   "reqs_mo": 845},
    "GPT 5.6 Luna":      {"reqs_5hr": 2050,  "reqs_mo": 10250},
    "GLM-5.3-Flash":     {"reqs_5hr": 1580,  "reqs_mo": 7900},
    "GLM-5.3":           {"reqs_5hr": 220,   "reqs_mo": 1080},
    "GLM-5.2":           {"reqs_5hr": 880,   "reqs_mo": 4300},
    "GLM-5.1":           {"reqs_5hr": 880,   "reqs_mo": 4300},
    "Kimi K3":           {"reqs_5hr": 110,   "reqs_mo": 490},
    "Kimi K2.7 Code":    {"reqs_5hr": 1350,  "reqs_mo": 6750},
    "Kimi K2.6":         {"reqs_5hr": 1150,  "reqs_mo": 5750},
    "LongCat-2.0":       {"reqs_5hr": 11400, "reqs_mo": 57200},
    "MiMo-V2.5":         {"reqs_5hr": 30100, "reqs_mo": 150400},
    "MiMo-V2.5-Pro":     {"reqs_5hr": 3250,  "reqs_mo": 16300},
    "MiniMax M3":        {"reqs_5hr": 3200,  "reqs_mo": 16000},
    "MiniMax M2.7":      {"reqs_5hr": 3400,  "reqs_mo": 17000},
    "Muse Spark 1.3 Contributor": {"reqs_5hr": 45300, "reqs_mo": 226600},
    "Muse Spark 1.2 Contributor": {"reqs_5hr": 45300, "reqs_mo": 226600},
    "Qwen3.8 Max":       {"reqs_5hr": 160,   "reqs_mo": 810},
    "Qwen3.8 Flash":     {"reqs_5hr": 5400,  "reqs_mo": 27000},
    "Qwen3.7 Max":       {"reqs_5hr": 170,   "reqs_mo": 840},
    "Qwen3.7 Plus":      {"reqs_5hr": 4300,  "reqs_mo": 21600},
    "Qwen3.6 Plus":      {"reqs_5hr": 3300,  "reqs_mo": 16300},
    "DeepSeek V4 Pro":   {"reqs_5hr": 1050,  "reqs_mo": 5200},
    "DeepSeek V4 Flash": {"reqs_5hr": 7600,  "reqs_mo": 37800},
    "DeepSeek V4 Flash Vision Exp": {"reqs_5hr": 3800, "reqs_mo": 18900},
    "Hy4 preview":       {"reqs_5hr": 1350,  "reqs_mo": 6770},
    "Hy3":               {"reqs_5hr": 4300,  "reqs_mo": 21500},
    "Omen Alpha":        {"reqs_5hr": 11600, "reqs_mo": 57900},
}

DISPLAY_TO_ID = {
    "Grok 4.6": "grok-4.6",
    "GPT 5.6 Luna": "gpt-5.6-luna",
    "GLM-5.3-Flash": "glm-5.3-flash",
    "GLM-5.3": "glm-5.3",
    "GLM-5.2": "glm-5.2",
    "GLM-5.1": "glm-5.1",
    "Kimi K3": "kimi-k3",
    "Kimi K2.6": "kimi-k2.6",
    "Kimi K2.7 Code": "kimi-k2.7-code",
    "LongCat-2.0": "longcat-2.0",
    "MiMo-V2.5": "mimo-v2.5",
    "MiMo-V2.5-Pro": "mimo-v2.5-pro",
    "MiniMax M3": "minimax-m3",
    "MiniMax M2.7": "minimax-m2.7",
    "Muse Spark 1.3 Contributor": "muse-spark-1.3-contributor",
    "Muse Spark 1.2 Contributor": "muse-spark-1.2-contributor",
    "Qwen3.8 Max": "qwen3.8-max",
    "Qwen3.8 Flash": "qwen3.8-flash",
    "Qwen3.7 Max": "qwen3.7-max",
    "Qwen3.7 Plus": "qwen3.7-plus",
    "Qwen3.6 Plus": "qwen3.6-plus",
    "DeepSeek V4 Pro": "deepseek-v4-pro",
    "DeepSeek V4 Flash": "deepseek-v4-flash",
    "DeepSeek V4 Flash Vision Exp": "deepseek-v4-flash-vision-exp",
    "Hy4 preview": "hy4-preview",
    "Hy3": "hy3",
    "Omen Alpha": "omen-alpha",
}

AA_SLUG_TO_MODEL_ID = {
    "grok-4-6":                "grok-4.6",
    "grok-4-5":                "grok-4.5",
    "gpt-5-6-luna-high":       "gpt-5.6-luna",
    "gpt-5-6-luna-xhigh":      "gpt-5.6-luna",
    "gpt-5-6-luna":            "gpt-5.6-luna",
    "glm-5-3-flash":           "glm-5.3-flash",
    "glm-5-3":                 "glm-5.3",
    "glm-5-2":                 "glm-5.2",
    "glm-5-1":                 "glm-5.1",
    "kimi-k3":                 "kimi-k3",
    "kimi-k2-7-code":          "kimi-k2.7-code",
    "kimi-k2-6":               "kimi-k2.6",
    "longcat-2-0":             "longcat-2.0",
    "mimo-v2-5-pro":           "mimo-v2.5-pro",
    "mimo-v2-5-0424":          "mimo-v2.5",
    "minimax-m3":              "minimax-m3",
    "minimax-m2-7":            "minimax-m2.7",
    "minimax-m2-5":            "minimax-m2.5",
    "muse-spark-1-3":          "muse-spark-1.3-contributor",
    "muse-spark-1-2":          "muse-spark-1.2-contributor",
    "qwen3-8-max":             "qwen3.8-max",
    "qwen3-8-flash-next":      "qwen3.8-flash",
    "qwen3-7-max":             "qwen3.7-max",
    "qwen3-7-plus":            "qwen3.7-plus",
    "qwen3-6-plus":            "qwen3.6-plus",
    "deepseek-v4-pro":         "deepseek-v4-pro",
    "deepseek-v4-flash":       "deepseek-v4-flash",
    "deepseek-v4-flash-vision": "deepseek-v4-flash-vision-exp",
    "hy3":                     "hy3",
}

# Priority for models with multiple effort variants: high → xhigh → max
# DeepSeek uses canonical 0813/0731 Max directly (68.8/69.1) — no fallback
AA_PRIORITY = {
    "gpt-5.6-luna":    ["gpt-5-6-luna-high", "gpt-5-6-luna-xhigh", "gpt-5-6-luna"],
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
        return f"{base} \u27d0  {coding} \u00b7 \u25cf  {pk:,}k"
    return base

def main():
    aa_coding = load_aa_coding()
    # sort by coding descending (nulls last), tie-break alphabetically ascending
    sorted_items = sorted(MODELS.items(), key=lambda kv: (-(aa_coding.get(DISPLAY_TO_ID[kv[0]]) if aa_coding.get(DISPLAY_TO_ID[kv[0]]) is not None else -1), kv[0]))

    print("Model ID | Display Name | Reqs/5hr | Per Hour | Per Min | Coding | Product(k)")
    for display_name, data in sorted_items:
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
    for display_name, data in sorted_items:
        model_id = DISPLAY_TO_ID[display_name]
        coding = aa_coding.get(model_id)
        entries.append(f'        "{model_id}": {{"name": "{full_name(display_name, data["reqs_5hr"], data["reqs_mo"], coding)}"}}')

    print('"opencode-go": {\n      "modelOverrides": {\n' + ",\n".join(entries) + "\n      }\n    },")

if __name__ == "__main__":
    main()
```

## Extension: enabledModels name overrides

For the 17 models listed in `chezmoi/dot_pi/agent/settings.json` `enabledModels`, create **per-provider** `modelOverrides` in `chezmoi/dot_pi/agent/models.json` (`providers.<provider>.modelOverrides` keyed by bare model ID, e.g. `providers["aihubmix-oc"].modelOverrides["coding-glm-5.3-flash"]`, `providers["openrouter"].modelOverrides["google/gemini-3.8-flash"]`). Same `⟐`/`●` suffix format as opencode-go, but **pricing source differs** (not `go.mdx`):

- `aihubmix-am/*` and `aihubmix-oc/*` → `https://aihubmix.com/api/v1/models?type=llm` (`pricing.input/output/cache_read`)
- `openrouter/*` → `https://models.dev/api.json` `openrouter.models` cost
- `opencode-go/*` and `opencode/*` already covered by go.mdx table — reuse same `reqs_mo` for those 8 entries; do **not** recompute with uniform mix

For non-opencode (aihubmix/openrouter), compute synthetic monthly capacity with a **uniform token mix `500 input / 50,000 cached / 200 output`** for *all* models and a **$60 monthly budget** (same budget as Go):

```
cost_per_req = (500*input + 50000*cache_read + 200*output) / 1_000_000   # USD
reqs_mo      = 60 / cost_per_req   # rounded nearest int; if price is 0 (free) → reqs_mo = null → omit ● product
productk     = round(reqs_mo * coding / 1000)  # omit if coding is null or reqs_mo is null
```

Free models (`coding-glm-5.2-free` $0/$0) have `cost_per_req = 0` → no `●` product, only `⟐ coding` if available. `agnes-2.5-flash` has no AA coding yet (null) → name stays `Display (reqs: …)` without suffix.

**Do not re-sort `enabledModels` array** — keep `settings.json` order as user set. Only `modelOverrides` objects are sorted descending by `⟐` per the Ordering rule above (also applied per-provider for these new overrides).

### EnabledModels AA & Pricing Mapping

| `enabledModels` entry | AA Slug (coding) | Pricing source `model_id` / `openrouter` key |
| `opencode-go/muse-spark-1.3-contributor` | `muse-spark-1-3` 76.3 | go.mdx `Muse Spark 1.3 Contributor` 45300/5hr |
| `opencode-go/deepseek-v4-flash` | `deepseek-v4-flash` 69.1 (0731 Max) | go.mdx 7600/5hr |
| `opencode-go/hy3` | `hy3` 58.8 | go.mdx 4300/5hr |
| `aihubmix-oc/deepseek-v4-flash-0731-fast` | `deepseek-v4-flash` 69.1 | aihubmix `deepseek-v4-flash-0731-fast` $0.28/$1.4 cache 0.07 |
| `aihubmix-oc/deep-deepseek-v4-flash-vision-exp` | `deepseek-v4-flash-vision` 65 *fallback* (no `-exp` slug in AA) | aihubmix `deepseek-v4-flash-vision-exp` $0.142/$0.284 cache 0.0284 |
| `aihubmix-oc/coding-glm-5.3-flash` | `glm-5-3-flash` 71.5 | aihubmix `glm-5.3-flash` $0.11268/$0.39438 cache 0.02817 |
| `aihubmix-oc/glm-5.3-flash` | `glm-5-3-flash` 71.5 | aihubmix `glm-5.3-flash` $0.11268/$0.39438 cache 0.02817 |
| `aihubmix-oc/qwen3.8-flash` | `qwen3-8-flash-next` 73.1 *fallback* (no `qwen3-8-flash` in AA) | aihubmix `qwen3.8-flash` $0.1126/$0.380025 cache 0.014075 |
| `aihubmix-oc/agnes-2.5-flash` | `agnes-2-5-pro-alpha` 58.8 *fallback* (no `agnes-2-5-flash` in AA yet, null would omit `⟐`; using pro-alpha as closest) | aihubmix `agnes-2.5-flash` $0.03/$0.15 |
| `aihubmix-am/cc-minimax-m3` | `minimax-m3` 58.6 | aihubmix `cc-minimax-m3` $0.1/$0.1 |
| `aihubmix-oc/coding-xiaomi-mimo-v2.5` | `mimo-v2-5-0424` 56.8 | aihubmix `coding-xiaomi-mimo-v2.5` $0.08/$0.16 cache 0.0016 |
| `openrouter/inclusionai/ling-3.0-flash-fin:free` | `ling-3-0-flash` 50.6 | free tier — price $0 → `⟐ coding` only, no `●` |
| `openrouter/google/gemini-3.8-flash` | `gemini-3-8-flash` 76.3 (high) | models.dev `openrouter` `google/gemini-3.8-flash` $0.75/$3.75 cache 0.075 |
| `vercel-ai-gateway/inclusionai/ling-3.0-flash` | `ling-3-0-flash` 50.6 | models.dev `openrouter` `inclusionai/ling-3.0-flash` $0.021/$0.063 cache 0.0042 |
| `vercel-ai-gateway/xiaomi/mimo-v2.5` | `mimo-v2-5-0424` 56.8 | models.dev `xiaomi/mimo-v2.5` (vercel section; same cost as openrouter `xiaomi/mimo-v2.5` $0.14/$0.28 cache 0.0028) |
| `vercel-ai-gateway/openai/gpt-5.4-nano` | `gpt-5-4-nano` 56.1 (xhigh) | models.dev `openai/gpt-5.4-nano` $0.2/$1.25 cache 0.02 |
| `opencode-go/mimo-v2.5` | `mimo-v2-5-0424` 56.8 | go.mdx 30100/5hr |

### Python for enabledModels (uniform 500/50k/200)

```python
# After the opencode-go block, also run for enabledModels
import json, re

ENABLED_MODELS = [
  "opencode-go/muse-spark-1.3-contributor",
  "opencode-go/deepseek-v4-flash",
  "opencode-go/hy3",
  "aihubmix-oc/deepseek-v4-flash-0731-fast",
  "aihubmix-oc/deep-deepseek-v4-flash-vision-exp",
  "aihubmix-oc/coding-glm-5.3-flash",
  "aihubmix-oc/glm-5.3-flash",
  "aihubmix-oc/qwen3.8-flash",
  "aihubmix-oc/agnes-2.5-flash",
  "aihubmix-am/cc-minimax-m3",
  "aihubmix-oc/coding-xiaomi-mimo-v2.5",
  "openrouter/inclusionai/ling-3.0-flash-fin:free",
  "openrouter/google/gemini-3.8-flash",
  "vercel-ai-gateway/inclusionai/ling-3.0-flash",
  "vercel-ai-gateway/xiaomi/mimo-v2.5",
  "vercel-ai-gateway/openai/gpt-5.4-nano",
  "opencode-go/mimo-v2.5",
]
# AA slug mapping for enabledModels (reuse AA_SLUG_TO_MODEL_ID where possible)
ENABLED_AA = {
  "opencode-go/muse-spark-1.3-contributor": "muse-spark-1-3",
  "opencode-go/deepseek-v4-flash": "deepseek-v4-flash",
  "opencode-go/hy3": "hy3",
  "aihubmix-oc/deepseek-v4-flash-0731-fast": "deepseek-v4-flash",
  "aihubmix-oc/deep-deepseek-v4-flash-vision-exp": "deepseek-v4-flash-vision",
  "aihubmix-oc/coding-glm-5.3-flash": "glm-5-3-flash",
  "aihubmix-oc/glm-5.3-flash": "glm-5-3-flash",
  "aihubmix-oc/qwen3.8-flash": "qwen3-8-flash-next",  # fallback, no qwen3-8-flash in AA
  "aihubmix-oc/agnes-2.5-flash": "agnes-2-5-pro-alpha",  # fallback, AA has no flash yet
  "aihubmix-am/cc-minimax-m3": "minimax-m3",
  "aihubmix-oc/coding-xiaomi-mimo-v2.5": "mimo-v2-5-0424",
  "openrouter/inclusionai/ling-3.0-flash-fin:free": "ling-3-0-flash",
  "openrouter/google/gemini-3.8-flash": "gemini-3-8-flash",
  "vercel-ai-gateway/inclusionai/ling-3.0-flash": "ling-3-0-flash",
  "vercel-ai-gateway/xiaomi/mimo-v2.5": "mimo-v2-5-0424",
  "vercel-ai-gateway/openai/gpt-5.4-nano": "gpt-5-4-nano",
  "opencode-go/mimo-v2.5": "mimo-v2-5-0424",
}
# pricing helpers
def cost_per_req_aih(pricing):  # pricing from aihubmix
    inp = pricing.get("input",0) or 0
    out = pricing.get("output",0) or 0
    cache = pricing.get("cache_read", pricing.get("cacheRead", pricing.get("cache",0))) or 0
    return (500*inp + 50000*cache + 200*out)/1_000_000

def cost_per_req_or(pricing):  # pricing from models.dev openrouter
    inp = pricing.get("input",0) or 0
    out = pricing.get("output",0) or 0
    cache = pricing.get("cache_read", pricing.get("cacheRead",0)) or 0
    return (500*inp + 50000*cache + 200*out)/1_000_000

def full_name_enabled(display, coding, reqs_mo):
    # reqs_mo may be None for free; coding may be None
    # For enabledModels we still want (reqs: N/hr M/min) if reqs_mo is not None,
    # else just display without reqs? For consistency, show reqs derived from reqs_mo/21600? Simplified: if reqs_mo use reqs_mo/4320*? Actually go.mdx: reqs_mo vs reqs_5hr not directly linked for uniform. For uniform, derive reqs_5hr = reqs_mo *5hr/mo ratio? Go: reqs_5hr = reqs_mo * (5hr/730hr) approx 0.00684. Instead, compute reqs_5hr = round(reqs_mo * 5 / 730) ??? Simpler: show (reqs: X/mo) not per-hr. But to keep format, compute per-hr as reqs_mo/730*5? For now, if reqs_mo is not None, compute per-hr/min from synthetic reqs_5hr.
    if reqs_mo is None:
        base = display
    else:
        reqs_5hr = round(reqs_mo * 5 / 730)  # 730hr per month avg
        ph = round(reqs_5hr/5)
        pm = round(reqs_5hr/5/60,1)
        base = f"{display} (reqs: {ph}/hr {pm}/min)"
    if coding is not None:
        # product only if both
        if reqs_mo is not None:
            pk = round(reqs_mo * coding / 1000)
            return f"{base} \u27d0  {coding} \u00b7 \u25cf  {pk:,}k"
        else:
            return f"{base} \u27d0  {coding}"
    return base
```

Write results to `providers.<provider>.modelOverrides` keyed by bare model ID, sorted descending by `⟐` per-provider (same ordering rule). Keep `settings.json` `enabledModels` order unchanged.

## Common Mistakes to Avoid

1. **Fetching truncated docs**: `curl https://raw.githubusercontent.com/...` returns ~32 lines. Use `gh api ... | base64 -d` to get the full 288 lines.

2. **Wrong per-minute calculation**: Per-minute is `reqs_5hr / 5 / 60`, NOT `per_hour / 60`. Calculate both values from the original `requests per 5 hours` value.

3. **Swapped rate limits**: Verify cheaper models have MORE requests/hr than expensive ones. For example Qwen3.7 Plus should be ~860/hr while Qwen3.7 Max is ~68/hr, and Qwen3.6 Plus ~660/hr vs Qwen3.8 Max ~32/hr. If you see the expensive Max with higher limits, you swapped rows.

4. **Inconsistent naming**: Use exact display names from docs verbatim (e.g., `GLM-5.3` not `GLM 5.3`, `GPT 5.6 Luna` not `GPT-5.6-Luna`, `Muse Spark 1.2 Contributor` not `Muse Spark 1.2`). MiMo-V2.5 and MiMo-V2.5-Pro are distinct models — do not conflate them.

5. **Missing AA data fetch**: If AA API returns an error or empty data, skip the analytics suffix for all models rather than failing. Log the error, proceed with rate-limit-only names.

6. **Stale AA data in cache**: Always re-fetch `/var/tmp/aa.json` each run. Do not reuse a cached copy.

7. **Wrong AA slug**: AA slugs use hyphens (e.g. `glm-5-2`, `mimo-v2-5-0424`, `muse-spark-1-2`), while OpenCode Go model IDs use dots (e.g. `glm-5.2`). The `AA_SLUG_TO_MODEL_ID` mapping handles this — do not attempt to derive one from the other algorithmically.

8. **Missing new models**: The catalog now has 27 models (not 20). If `go.mdx` row count ≠ `len(MODELS)`, update the skill — do not silently drop new models like `grok-4.6`, `glm-5.3-flash`, `longcat-2.0`, `qwen3.8-flash`, `deepseek-v4-flash-vision-exp`, `hy4-preview`, `omen-alpha`, `muse-spark-1.3-contributor`. Note removed models too (`grok-4.5` dropped from live docs 2026-09-05 but kept as stale override; `qwen3.7-max` rates changed 340→170/5hr).

9. **Trailing commas / invalid JSON**: `chezmoi/dot_pi/agent/models.json` must be strict JSON (no trailing commas). Validate with `python3 -m json.tool` or `jq` — previously the file had trailing commas and failed both.
