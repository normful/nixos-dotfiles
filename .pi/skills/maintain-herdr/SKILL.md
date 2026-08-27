---
name: maintain-herdr
description: Maintain and upgrade herdr pin in flake.nix/flake.lock plus config.toml compatibility. Handles org migration ogulcancelik → herdrdev, stable/preview channel choice, lock update, and config check via herdr config check.
---

# Maintain Herdr

> **Document status:** Active  
> **Authoritative files:**  
> - `flake.nix` line 32 — `herdr.url = "github:herdrdev/herdr/<tag>"` (migrated from `ogulcancelik/herdr`)  
> - `flake.lock` node `herdr` — locked `rev`/`narHash` for that tag  
> - `chezmoi/dot_config/herdr/config.toml` (chezmoi source; installs to `~/.config/herdr/config.toml`)  

This skill maintains the herdr version pin and its config. It covers **both** the Nix flake bump (with org migration) **and** config compatibility advisory.

## When to Use

- Herdr releases a new stable tag (e.g. `v0.8.0` → `v0.8.2`) or preview build (`preview-YYYY-MM-DD-<sha>`)
- `herdr config check` reports unknown/deprecated keys after upgrade
- `flake.nix` still points at legacy `ogulcancelik/herdr` and should be migrated to `herdrdev/herdr`
- `herdr --version` does not match the pinned tag after `darwin-rebuild`

## Sources of Truth

| Source | Command / URL | Notes |
|--------|---------------|-------|
| Latest stable | `gh api repos/herdrdev/herdr/releases/latest --jq .tag_name` | Returns `vX.Y.Z` (e.g. `v0.8.2`). Requires `gh` auth. |
| Latest including preview | `gh api repos/herdrdev/herdr/releases --jq '.[0].tag_name'` | First entry is newest (preview if newer than stable). Or `git ls-remote --tags https://github.com/herdrdev/herdr.git` |
| All tags (no API) | `git ls-remote --tags https://github.com/herdrdev/herdr.git \| grep -E 'refs/tags/v0\.'` | Fallback without `gh`. Sort with `sort -V` to find max. |
| Docs / config reference | `https://herdr.dev/docs/configuration/` + `https://herdr.dev/docs` version picker | Verify new keys: `ui.window_title`, `ui.pane_outer_borders`, `keys.move_tab_*`, `keys.resize_pane_*`, etc. |
| Version-pinned config docs | `https://raw.githubusercontent.com/herdrdev/herdr/refs/tags/v<VER>/docs/versions/<VER>/website/src/content/docs/configuration.mdx` e.g. `https://raw.githubusercontent.com/herdrdev/herdr/refs/heads/master/docs/versions/0.8.2/website/src/content/docs/configuration.mdx` | Narrative docs for the *target* tag. Preview fallback: `refs/heads/master/docs/versions/<base VER>/...` |
| Canonical defaults | `herdr --default-config` (post-rebuild) / `nix run github:herdrdev/herdr/<tag>#herdr -- --default-config` (pre-rebuild) | Ground truth for every key; `config-reference.mdx` at that raw URL is just `<ConfigReference />` wrapper — do not parse it for keys |
| Changelog | `https://github.com/herdrdev/herdr/blob/master/CHANGELOG.md` + Releases page | Check **Added/Changed/Fixed** for deprecated `ui.agent_panel_scope` etc. |
| Local config | `chezmoi/dot_config/herdr/config.toml` | Run `herdr config check` to validate (reports unknown theme names, deprecated keys). |
| Installed version | `herdr --version` / `nix flake metadata --json \| jq '.locks.nodes.herdr'` | Cross-check after rebuild. |

## Target Files

| File | What to edit |
|------|-------------|
| `flake.nix:32` | `herdr.url = "github:herdrdev/herdr/<tag>";` — **migrate** `ogulcancelik` → `herdrdev` if present; replace tag |
| `flake.lock` | **Never edit manually** — regenerated via `nix flake lock --update-input herdr` |
| `chezmoi/dot_config/herdr/config.toml` | Only if `herdr config check` warns; keep keybindings/themes, remove retired keys |

## Process

```
│ 1. Choose channel  │
│    stable / preview │
         ▼
│ 2. Fetch latest tag │
│    gh api / ls-remote│
         ▼
│ 3. Update flake.nix  │
│    herdr.url + org  │
         ▼
│ 4. Update flake.lock │
│    nix flake lock    │
         ▼
│ 5. Validate config   │
│    herdr config check│
         ▼
│ 5b. Discover new /   │
│  unconfigured opts   │  ← advisory: surface, don't auto-enable
         ▼
│ 6. Advise / stage    │
│    commit + rebuild  │
│    (user runs)       │
```

## Quick Reference

| Step | Command | Purpose |
|------|---------|---------|
| Choose channel | `socrates` prompt: stable vs preview | User intent |
| Fetch stable | `gh api repos/herdrdev/herdr/releases/latest --jq .tag_name` | e.g. `v0.8.2` |
| Fetch preview | `gh api repos/herdrdev/herdr/releases --jq '.[0].tag_name'` | e.g. `preview-2026-08-19-b5c4a01` |
| Fallback (no gh) | `git ls-remote --tags https://github.com/herdrdev/herdr.git \| cut -f2 \| grep 'refs/tags/v' \| sort -V \| tail -1 \| sed 's|refs/tags/||'` | Get latest tag without API |
| Update flake | Edit `flake.nix` line 32 | `herdr.url = "github:herdrdev/herdr/<tag>";` |
| Update lock | `nix flake lock --update-input herdr` | Regenerates `flake.lock` `herdr` node |
| Check config | `herdr config check` | Reports unknown/deprecated keys |
| Discover new opts | `herdr --default-config` + `comm -23` vs local + `configuration.mdx` at `docs/versions/<VER>/...` | Advisory: surface unconfigured keys; suppress any explicit config as decided (2026-08-26: no secondary differs) |
| Show diff | `git diff flake.nix flake.lock` | Review pin + narHash change |
| Prep commit | `git add flake.nix flake.lock` | Stage (do not auto-commit per semi-auto policy) |
| Verify after rebuild | `herdr --version` + `nix flake metadata --json \| jq '.locks.nodes.herdr.original.ref'` | Confirm running version matches pin |

## Implementation

### Step 1: Offer Channel Choice

Always ask via `socrates` (per user preference — never assume stable):

- **Stable** — `gh api repos/herdrdev/herdr/releases/latest --jq .tag_name` (e.g. `v0.8.2`)
- **Preview** — `gh api repos/herdrdev/herdr/releases --jq '.[0].tag_name' | select(startswith("preview-"))` or `git ls-remote --tags` filtered for `preview-`

If user picks **stable** but preview is newer, note it: “Latest preview is `preview-...` (base `v0.8.2`) — still bump to stable `v0.8.2`?”

### Step 2: Fetch Latest Tag

**Preferred (with `gh`):**
```bash
# stable
gh api repos/herdrdev/herdr/releases/latest --jq .tag_name
# → v0.8.2

# preview-aware (newest release overall)
gh api repos/herdrdev/herdr/releases --jq '.[0].tag_name'
# → preview-2026-08-19-b5c4a0176e91  or  v0.8.2
```

**Fallback (no `gh`):**
```bash
git ls-remote --tags https://github.com/herdrdev/herdr.git \
  | cut -f2 | grep 'refs/tags/v' | sed 's|refs/tags/||' | sed 's|\^{}||' \
  | sort -V | tail -1
# also check preview tags:
git ls-remote --tags https://github.com/herdrdev/herdr.git \
  | cut -f2 | grep 'refs/tags/preview-' | sort -V | tail -1
```

Verify tag exists: `gh api repos/herdrdev/herdr/releases/tags/v0.8.2 --jq .tag_name` or `git ls-remote --tags https://github.com/herdrdev/herdr.git refs/tags/v0.8.2`.

### Step 3: Update flake.nix (with Org Migration)

Edit `flake.nix:32`:

**Before (legacy):**
```nix
herdr.url = "github:ogulcancelik/herdr/v0.8.0";
```

**After (stable):**
```nix
herdr.url = "github:herdrdev/herdr/v0.8.2";
```

**After (preview):**
```nix
herdr.url = "github:herdrdev/herdr/preview-2026-08-19-b5c4a0176e91";
```

Rules:
- Always migrate `ogulcancelik` → `herdrdev` if detected. Note in commit body: `migrate: ogulcancelik/herdr → herdrdev/herdr (canonical org)`.
- Keep `herdr.inputs.nixpkgs.follows = "nixpkgs-unstable-2611";` line untouched (line 33).
- Only the tag after the final `/` changes.

### Step 4: Update flake.lock (Never Edit Manually)

```bash
nix flake lock --update-input herdr
```

Verify:
```bash
jq '.nodes.herdr | {orig: .original.ref, locked: .locked.rev, narHash: .locked.narHash}' flake.lock
# expect: orig == chosen tag, locked.rev == 40-char sha, narHash == sha256-...
git diff --stat flake.lock
```

If lock fails due to stale `nixpkgs-unstable-2611`, run `nix flake lock --update-input nixpkgs-unstable-2611` only if user agrees — otherwise keep scope to `herdr`.

### Step 5: Validate config.toml

```bash
herdr config check
# expect: no output or only warnings about deprecated keys
```

Common outputs and fixes:

| Warning | Fix in `chezmoi/dot_config/herdr/config.toml` |
|---------|-----------------------------------------------|
| `unknown key ui.agent_panel_scope` | Delete line — retired (v0.8.x silently ignores, but check flags it) |
| `unknown theme name ...` | Fix typo or revert to built-in theme (rose-pine, etc.) — `herdr config check` now errors on unknown themes since v0.8.2 |
| `unknown key ...` for renamed keys | Consult https://herdr.dev/docs/configuration/ — remove or rename |

If clean, no edit needed. If warnings, edit `chezmoi/dot_config/herdr/config.toml` and re-run `herdr config check` until clean.

### Step 5b: Discover New / Unconfigured Settings & Keybinds (Advisory — Do Not Auto-Enable)

After `herdr config check` is clean, diff the *target version's* documented surface against `chezmoi/dot_config/herdr/config.toml` and surface anything unconfigured. Do not auto-enable — surface only.

**Decision rule — explicit config means decided (per user preference 2026-08-26):**
- If a key **does not appear** in `config.toml` at all → candidate to surface in primary "unconfigured" table.
- If a key **appears in any form** (`= ""`, `= []`, `= false`, `= 0`, `= true`, `= "value"`, etc.) → **never surface** — explicit config is respected. Treat as decided and skip forever. This covers your 30 blanked keybinds like `focus_pane_left = ""`, `switch_tab = ""`, etc., **and** your intentional `= false`/`true` overrides like `update.version_check = false`, `ui.prompt_new_tab_name = false`, `ui.toast.clipboard.enabled = true`, `ui.sound.enabled = false`. Do not re-surface these as "differs from default".
- **No secondary table** — never surface a "differs from default" table. When you explicitly set `version_check = false` where default is `true`, that is respected, not advisory.

This ensures future you is not re-asked about anything you deliberately configured. For a new upstream key you haven't decided yet (e.g. `keys.move_tab_next` absent in your file), it surfaces **once**; if you then add `keys.move_tab_next = ""` to record "keep disabled" (or any explicit value), it is suppressed on all future bumps.

**1. Resolve docs URL for the target tag (example: `v0.8.2` → `docs/versions/0.8.2/website/src/content/docs/configuration.mdx`):**
```bash
TAG=v0.8.2; VER=${TAG#v}  # from Step 2
# stable
curl -fsSL "https://raw.githubusercontent.com/herdrdev/herdr/refs/tags/${TAG}/docs/versions/${VER}/website/src/content/docs/configuration.mdx" -o /tmp/herdr-config-docs.mdx
# preview fallback (no versioned docs yet)
curl -fsSL "https://raw.githubusercontent.com/herdrdev/herdr/refs/heads/master/docs/versions/${VER}/website/src/content/docs/configuration.mdx" -o /tmp/herdr-config-docs.mdx
# in-agent preferred: ctx_url_read(url) for markdown
```
Also filter `CHANGELOG.md` at same ref for `### Added` since last pin to prioritize new keys.

**2. Get canonical key list (authoritative over `configuration.mdx` narrative):**
```bash
# canonical defaults (post-rebuild, or pre-rebuild via nix run)
herdr --default-config > /tmp/herdr.default.toml
# or without rebuilding:
nix run github:herdrdev/herdr/${TAG}#herdr -- --default-config > /tmp/herdr.default.toml

# presence check — key name only, value ignored except for "" / [] filter
grep -E '^\s*[^#].*=' chezmoi/dot_config/herdr/config.toml | cut -d= -f1 | sed 's/^ *//;s/ *$//' | sort -u > /tmp/local_keys_present.txt
grep -E '=\s*""\s*$|=\s*\[\s*\]\s*$' chezmoi/dot_config/herdr/config.toml | cut -d= -f1 | sed 's/^ *//' | sort -u > /tmp/local_explicit_empty.txt
# defaults leaf keys (strip comment prefix) — filtered 2026-08-26 to exclude delivery-enum artifacts (herdr/off/system/terminal)
# Only include lines whose value looks like TOML (quoted string, array, bool, number, reset) — skips "# off = disable..." etc.
grep -E '^\s*#\s*[a-z_][a-z0-9_]*\s*=\s*("[^"]*"|\x27[^\x27]*\x27|\[.*\]|true|false|[0-9\-]|reset)' /tmp/herdr.default.toml | sed -E 's/^\s*#\s*//' | cut -d= -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sort -u | grep -vE '^(herdr|off|system|terminal)$' > /tmp/default_keys.txt
```

**3. Diff → advisory table (primary only — no secondary):**
- **Primary "unconfigured"** = `comm -23 /tmp/default_keys.txt /tmp/local_keys_present.txt` minus any key in `/tmp/local_explicit_empty.txt` (should already be excluded, but now any present key is excluded — explicit config is decided) — group by table for readability (e.g. `ui.window_title`, `ui.pane_outer_borders`, `ui.status_indicators`, `ui.tab_bar_right*`, `ui.sidebar.*.rows`, `keys.move_tab_*`, `keys.resize_pane_*`, `terminal.shell_mode`, `server.headless_*`, `remote.manage_ssh_config`). Exclude noisy leaves like individual color tokens unless `theme.custom` table itself is absent.
- **No secondary table** — do not build or surface "differs from default" (e.g. `update.version_check = false` vs `true`, `ui.prompt_new_tab_name = false` vs `true`) — these are explicitly configured and respected per user preference 2026-08-26. Suppress entirely.
- **Do not parse `config-reference.mdx` at the raw URL** — verified 2026-08-26 it renders via `<ConfigReference />` and contains no key table; use `--default-config` as ground truth and `configuration.mdx` only for human context.

Present as advisory via `socrates`:

> "Target `v0.8.2` adds N unconfigured groups you haven't decided: [primary table]. Keep disabled, or pick any to stage? (no auto-enable — explicit config like `ui.toast.clipboard.enabled = true` is already respected and not re-surfaced)"

Example primary for `v0.8.0 → v0.8.2` with your current config (`v0.8.2` pinned, 29 `= ""` suppressed): `ui.window_title`, `ui.pane_outer_borders`, `ui.status_indicators`, `ui.tab_bar_right`/`tab_bar_right_separator`/`tab_bar_position`, `ui.sidebar.agents.rows`/`row_gap`/`rows_by_agent`, `ui.sidebar.spaces.rows`, `keys.move_tab_previous`/`move_tab_next`, `keys.resize_pane_left/down/up/right`, `terminal.default_shell`/`shell_mode`, `server.headless_cols`/`headless_rows`, `remote.manage_ssh_config`.

**4. Stage only on opt-in:**
If user picks a key to enable, append it to `chezmoi/dot_config/herdr/config.toml` commented with context and re-run `herdr config check`:
```toml
# Added in v0.8.2 — see https://herdr.dev/docs/configuration/#outer-terminal-window-title
# window_title = "{hostname}: {workspace}"
```
If user picks "keep disabled" for a primary candidate, record intent so future runs suppress it:
```toml
# Added in v0.8.2 — intentionally disabled (was unconfigured, now decided)
move_tab_next = ""
```
Only write `= ""` / `= []` entries when user explicitly chooses "keep disabled" — never infer.

### Step 6: Stage and Advise (Semi-Auto — Do Not Auto-Commit/Rebuild)

```bash
git diff flake.nix flake.lock
git add flake.nix flake.lock
# if config.toml changed:
git add chezmoi/dot_config/herdr/config.toml
```

Provide user with ready-to-run commands (do not execute):

```bash
git commit -m "chore: update herdr to v0.8.2

migrate: ogulcancelik/herdr → herdrdev/herdr (canonical org)
herdr: v0.8.0 → v0.8.2 (rev 9eb5214)

Co-authored-by: herdr-maintainer"
sudo darwin-rebuild switch --flake $HOME/code/nixos-dotfiles#cyan
herdr --version
herdr config check
nix flake metadata --json | jq '.locks.nodes.herdr'
```

Commit message template:
- Title: `chore: update herdr to <tag>` (`v0.8.2` or `preview-...`)
- Body: org migration note if applicable, old→new tag, locked rev short-hash from `flake.lock`

## Verification Checklist

- [ ] `flake.nix` uses `herdrdev/herdr/<tag>` (not `ogulcancelik`)
- [ ] `flake.lock` `nodes.herdr.original.ref` == chosen tag
- [ ] `flake.lock` `nodes.herdr.locked.rev` is 40-char, `narHash` present
- [ ] `herdr config check` exits 0 (no unknown/deprecated keys)
- [ ] Unconfigured options from target `<VER>` docs surfaced (advisory, none auto-enabled; any explicit config — `= ""`/`= []`/`= false`/`= true`/`= "value"` — treated as decided and not re-surfaced; no secondary differs per 2026-08-26)
- [ ] After user runs `darwin-rebuild`, `herdr --version` matches tag

## Common Mistakes to Avoid

| Mistake | Fix |
|---------|-----|
| Manually editing `flake.lock` | Always use `nix flake lock --update-input herdr`; never hand-edit `rev`/`narHash` |
| Forgetting org migration | Replace `ogulcancelik` with `herdrdev` — canonical since mid-2026; both redirect but `herdrdev` is authoritative |
| Using `curl https://raw.githubusercontent.com/...` for releases | Use `gh api` or `git ls-remote --tags`; raw content truncates |
| Assuming stable when preview is requested | Always prompt channel choice via `socrates`; preview tags are `preview-YYYY-MM-DD-<sha>` |
| Editing `herdr.inputs.nixpkgs.follows` line | Leave `herdr.inputs.nixpkgs.follows = "nixpkgs-unstable-2611";` untouched |
| Auto-committing or auto-rebuilding | Semi-auto policy: stage + advise, let user commit and `sudo darwin-rebuild` |
| Ignoring `herdr config check` warnings | Run after every bump; retired `ui.agent_panel_scope` and unknown themes now error |
| Bumping without checking CHANGELOG | Review https://github.com/herdrdev/herdr/releases for breaking config changes before bumping |
