---
name: update-nixpkgs-unstable
description: Update nixpkgs-unstable reference in flake.nix to latest commit
---

# Update nixpkgs-unstable

## Overview

**Update pinned nixpkgs-unstable commit to latest upstream.**

This skill documents the process for updating the unstable nixpkgs reference from a pinned commit hash to the current HEAD of `nixpkgs-unstable` branch.

## When to Use

- Updating `flake.nix` to latest nixpkgs-unstable
- Running `git ls-remote` to fetch commit hash
- Commit changes (but dont push them)
- Triggering macOS rebuild with `darwin-rebuild`

## Process

```
┌─────────────────┐
│ 1. Fetch latest │
│    commit hash  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 2. Update       │
│    flake.nix    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 3. Commit       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 4. Run sudo     │
│    darwin-rebuild│
└─────────────────┘
```

## Quick Reference

| Step | Command | Purpose |
|------|---------|---------|
| Fetch hash | `git ls-remote https://github.com/NixOS/nixpkgs.git refs/heads/nixpkgs-unstable \| cut -f1` | Get latest commit |
| Update flake | Edit line with `nixpkgs-unstable-*.url` | Replace old hash |
| Commit | `git add flake.nix && git commit -m "chore: update nixpkgs-unstable to \<hash\>"` | Stage & commit |
| Rebuild | `sudo darwin-rebuild switch --flake $HOME/code/nixos-dotfiles#cyan` | Apply to macOS |

## Implementation

### Step 1: Fetch Latest Commit

```bash
git ls-remote https://github.com/NixOS/nixpkgs.git refs/heads/nixpkgs-unstable | cut -f1
```

**Output:** `<some new commit hash>` (example value only)

### Step 2: Update flake.nix

Edit the `flake.nix` file at line 7 (where `nixpkgs-unstable` is defined):

**Before:**
```nix
nixpkgs-unstable-2611.url = "github:NixOS/nixpkgs/<old commit hash>";
```

**After:**
```nix
nixpkgs-unstable-2611.url = "github:NixOS/nixpkgs/<some new commit hash>";
```

### Step 3: Commit Changes

```bash
git add flake.nix
git commit -m "chore: update nixpkgs-unstable"
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Forgetting to stage file | Run `git add flake.nix` before commit |
| Copying incomplete hash | Verify hash is 40 characters (full SHA) |
