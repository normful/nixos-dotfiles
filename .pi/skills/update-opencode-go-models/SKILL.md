---
name: update-opencode-go-models
description: Update OpenCode Go model rate limits and availability in chezmoi/dot_pi/agent/models.json
---

# Update OpenCode Go Models

> **Document status:** Draft

## Overview

Keep `chezmoi/dot_pi/agent/models.json` in sync with OpenCode Go's live model catalog and rate limits.

**Scope:** Only the `providers.opencode-go.modelOverrides` object. This skill does **not** apply to the `openrouter` provider or the `xai` provider.

## Sources of Truth

- OpenCode Go rate limit tables (requests per 5hr / week / month): https://raw.githubusercontent.com/anomalyco/opencode/refs/heads/dev/packages/web/src/content/docs/go.mdx
- Canonical model ID list: Download JSON from https://models.dev/api.json and run jq to get the keys from the `".opencode-go".models`

## Target file to modify

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
