---
name: update-opencode-go-models
description: Update OpenCode Go model rate limits and availability in chezmoi/dot_pi/agent/models.json
---

# Update OpenCode Go Models

> **Document status:** Draft  
> **Source of truth:** `chezmoi/dot_pi/agent/models.json`  
> **Other docs to read first:** `chezmoi/dot_pi/agent/SYSTEM.md`

## Overview

Keep `chezmoi/dot_pi/agent/models.json` in sync with OpenCode Go's live model catalog and rate limits.

**Scope:** Only the `providers.opencode-go.modelOverrides` object. This skill does **not** apply to the `openrouter` provider (which uses a `models` array with `id`/`name`/`reasoning` fields) or the `xai` provider.

## Source of Truth

| Source | Purpose | Command |
|--------|---------|---------|
| OpenCode Go docs | Rate limit tables (requests per 5hr / week / month) | Browse `https://opencode.ai/docs/go.md` |
| models.dev API | Canonical model ID list | `curl -s https://models.dev/api.json \| jq '".opencode-go".models \| keys'` |

## File Location

`chezmoi/dot_pi/agent/models.json` — the `providers.opencode-go.modelOverrides` object.

## Name Format

All `name` fields must follow this exact pattern:

```
<Display Name> (reqs: <N>/hr <M>/min)
```

Where:
- `<N>` = requests per 5 hours ÷ 5 (round to nearest integer)
- `<M>` = `<N>` ÷ 60 (round to 1 decimal place)

## Process

```
┌─────────────────┐
│ 1. Fetch model  │
│    IDs from API │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 2. Read docs    │
│    rate tables  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 3. Compare with │
│    current JSON │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 4. Update names │
│    & add/remove │
│    model keys   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 5. Commit       │
└─────────────────┘
```

## Quick Reference

| Step | Command / Action |
|------|----------------|
| List model IDs | `curl -s https://models.dev/api.json \| jq '".opencode-go".models \| keys'` |
| Read current config | `cat chezmoi/dot_pi/agent/models.json` |
| Edit | Update `providers.opencode-go.modelOverrides` |
| Commit | `git add chezmoi/dot_pi/agent/models.json && git commit -m "chore: update opencode-go models"` |

## Implementation

### Step 1: Fetch Canonical Model IDs

```bash
curl -s https://models.dev/api.json | jq '".opencode-go".models | keys'
```

**Purpose:** Detect newly added or removed models. Any ID in this list but missing from `modelOverrides` must be added. Any ID in `modelOverrides` but missing from this list should be removed.

### Step 2: Read Rate Limits from Docs

Open `https://opencode.ai/docs/go.md` and locate the rate limit table. Extract the **requests per 5 hour** value for each model.

### Step 3: Calculate Name Values

**Do not calculate manually.** Run this Python script with the rate limit data from the docs:

```python
models = {
    # "model-id": requests_per_5hr,
    "glm-5.1": 880,
    "glm-5": 1150,
    # ... add all models from the docs
}

for model_id, req5h in models.items():
    hr = round(req5h / 5)
    mn = round(hr / 60, 1)
    print(f'{model_id}: (reqs: {hr}/hr {mn}/min)')
```

**Formulas:**
- `hr  = round(requests_per_5hr / 5)`
- `min = round(hr / 60, 1)`

Example: MiMo V2 Omni with 2,150 requests per 5 hours
- hr:  2150 / 5  = 430
- min: 430 / 60  = 7.166... → **7.2**

Resulting name: `MiMo V2 Omni (reqs: 430/hr 7.2/min)`

### Step 4: Update JSON

Edit `chezmoi/dot_pi/agent/models.json`:

- **Add** new models as `"<model-id>": { "name": "<Display Name> (reqs: <N>/hr <M>/min)" }`
- **Update** existing model `name` fields when rate limits change
- **Remove** models no longer in the API response
- Keep keys in the same order as the API list (alphabetical by model ID)

### Step 5: Commit

```bash
git add chezmoi/dot_pi/agent/models.json
git commit -m "chore: update opencode-go models"
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using `requests_per_5hr / 60` for `/min` | Use `hr / 60` where `hr = requests_per_5hr / 5` |
| Forgetting to add new models | Always cross-check API key list |
| Wrong decimal precision | Use 1 decimal place for `/min` |
| Applying to `openrouter` provider | `openrouter` uses a `models` array, not `modelOverrides` |
| Not committing | Stage and commit the single file |
