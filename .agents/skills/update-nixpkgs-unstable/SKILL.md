---
name: update-nixpkgs-unstable
description: Use when bumping the nixpkgs-unstable pin in flake.nix. Fetch the hash, relock, verify evaluation, commit without pushing, and hand the darwin rebuild to the user.
---

# Update nixpkgs-unstable

## Overview

**Update pinned nixpkgs-unstable commit to latest upstream.**

This skill documents the process for updating the unstable nixpkgs reference from a pinned commit hash to the current HEAD of `nixpkgs-unstable` branch.

## When to Use

- Updating `flake.nix` to latest nixpkgs-unstable
- Running `git ls-remote` to fetch commit hash
- Committing changes (but never pushing them)
- Handing the macOS rebuild to the user — the agent does not run it

## Process

```
┌──────────────────────┐
│1. Fetch latest hash  │
└───────────┬──────────┘
            │
            ▼
┌──────────────────────┐
│2. Update flake.nix   │
└───────────┬──────────┘
            │
            ▼
┌──────────────────────┐
│3. Relock flake.lock  │
└───────────┬──────────┘
            │
            ▼
┌──────────────────────┐
│4. Evaluate config    │
└───────────┬──────────┘
            │
            ▼
┌──────────────────────┐
│5. Commit, no push    │
└───────────┬──────────┘
            │
            ▼
┌──────────────────────┐
│6. Hand sudo rebuild  │
│   to the user        │
└──────────────────────┘
```

## Quick Reference

| Step | Command | Purpose |
|------|---------|---------|
| Fetch hash | `git ls-remote https://github.com/NixOS/nixpkgs.git refs/heads/nixpkgs-unstable \| cut -f1` | Get latest commit |
| Update flake | Edit the `nixpkgs-unstable-*.url` line | Replace old hash |
| Relock | `nix flake lock --update-input nixpkgs-unstable-2611` | Regenerate `flake.lock` |
| Verify | `nix eval --raw .#darwinConfigurations.cyan.system` | Catch renamed attributes |
| Commit | `git add flake.nix flake.lock && git commit -m "chore: update nixpkgs-unstable to <hash>"` | Stage & commit, no push |
| Rebuild | `sudo darwin-rebuild switch --flake $HOME/code/nixos-dotfiles#cyan` | User runs this, not the agent |

## Implementation

### Step 1: Fetch Latest Commit

```bash
git ls-remote https://github.com/NixOS/nixpkgs.git refs/heads/nixpkgs-unstable | cut -f1
```

**Output:** `<some new commit hash>` (example value only)

### Step 2: Update flake.nix

Locate the pin — it is not at a fixed line number:

```bash
grep -n nixpkgs-unstable flake.nix
```

As of 2026-10 the attribute is `nixpkgs-unstable-2611` (named for the release it will become). Edit that line:

**Before:**
```nix
nixpkgs-unstable-2611.url = "github:NixOS/nixpkgs/<old commit hash>";
```

**After:**
```nix
nixpkgs-unstable-2611.url = "github:NixOS/nixpkgs/<some new commit hash>";
```

### Step 3: Relock flake.lock

Editing the URL does nothing until the lock file is regenerated.

```bash
nix flake lock --update-input nixpkgs-unstable-2611
```

`--update-input` is a deprecated alias for `nix flake update` and prints a
warning; it still works. Never hand-edit `flake.lock`.

Expect output of this shape, with the date moving to the new commit's date:

```
• Updated input 'nixpkgs-unstable-2611':
    'github:NixOS/nixpkgs/<old>' (2026-08-10)
  → 'github:NixOS/nixpkgs/<new>' (2026-10-20)
```

A nearly unchanged date means the pin already pointed at that commit.

### Step 4: Verify before committing

An unstable bump routinely lands on renamed packages, and evaluating is far
cheaper than discovering it during a rebuild.

```bash
nix eval --raw .#darwinConfigurations.cyan.system
```

Expect a `/nix/store/…-darwin-system-…` path. That is the only gate that
matters: cyan is the only configuration in the flake.

Then size the work the user is about to accept, so you can report it:

```bash
nix build --dry-run .#darwinConfigurations.cyan.system 2>&1 | grep -E '^these'
```

A multi-month jump can mean hundreds of derivations; that is the real cost of
the bump, not a problem to fix.

#### When evaluation fails with a rename

nixpkgs throws on renamed attributes instead of aliasing them:

```
error: 'typescript-go' has been renamed to/replaced by 'typescript'
```

Fix the reference in this repo; do not pin backwards. Confirm what the new
attribute actually is before substituting it:

```bash
nix eval --impure --expr 'let f = builtins.getFlake "/Users/norman/code/nixos-dotfiles"; p = f.inputs.nixpkgs-unstable-2611.legacyPackages.aarch64-darwin; in p.typescript.meta'
```

Observed 2026-10-20: `typescript-go` → `typescript`, which is now TypeScript 7
(`typescript_7`, the native `tsgo` compiler, `bin/tsc`). The npm compiler moved
to `typescript_5`. Check whether the substitution preserves the tool the user
wanted before committing it.

### Step 5: Commit

```bash
git add flake.nix flake.lock
git commit -m "chore: update nixpkgs-unstable to <new commit hash>"
```

Add any module file you touched while fixing a rename. Committing to `main` is
authorized in this repo; do not push.

### Step 6: Hand the rebuild to the user

```bash
sudo darwin-rebuild switch --flake $HOME/code/nixos-dotfiles#cyan
```

Do not run this. `sudo` needs an interactive password here (`sudo -n true`
returns `sudo: a password is required`), and the switch installs system-wide
packages on macOS. Report the dry-run size and the exact command instead.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Forgetting to stage file | Run `git add flake.nix flake.lock` before commit |
| Copying incomplete hash | Verify hash is 40 characters (full SHA) |
| Bumping the URL without relocking | Run `nix flake lock --update-input nixpkgs-unstable-2611`; otherwise the bump is a no-op |
| Hand-editing `flake.lock` | Regenerate it with `nix flake lock` |
| Committing without evaluating | `nix eval --raw .#darwinConfigurations.cyan.system` first |
| Pinning backwards around a rename | Substitute the new attribute, after checking what it now provides |
| Agent running `sudo darwin-rebuild` | Hand the command to the user |
| Pushing the commit | The skill commits only; the user decides when to push |
