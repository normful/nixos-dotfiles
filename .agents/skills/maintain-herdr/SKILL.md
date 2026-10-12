---
name: maintain-herdr
description: Maintain and upgrade herdr pin in flake.nix/flake.lock plus config.toml compatibility. Handles org migration ogulcancelik → herdrdev, stable/preview channel choice, lock update, and config check via herdr config check.
---

# Maintain Herdr

> **Document status:** Active  
> **Authoritative files:**  
> - `flake.nix` — `herdr.url` in the `inputs` block (line 26 as of v0.9.3; anchor on the key, not the line): `herdr.url = "github:herdrdev/herdr/<tag>";` (migrated from `ogulcancelik/herdr`)  
> - `flake.lock` node `herdr` — locked `rev`/`narHash` for that tag  
> - `chezmoi/dot_config/herdr/config.toml.tmpl` (chezmoi **template** — the repo has no plain `config.toml`; installs to `~/.config/herdr/config.toml`)  

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
| Version-pinned config docs | `https://raw.githubusercontent.com/herdrdev/herdr/refs/tags/<tag>/docs/versions/<DOCVER>/website/src/content/docs/configuration.mdx` | Narrative docs for the *target* tag. **`<DOCVER>` lags `<tag>`** — the dir matching the tag often does not exist (verified 2026-10-11: at tag `v0.9.3` the newest dir is `docs/versions/0.9.1`). Resolve it: `gh api "repos/herdrdev/herdr/git/trees/<tag>?recursive=1" --jq '.tree[].path' \| grep -oE '^docs/versions/[0-9.]+$' \| sort -V \| tail -1`. `docs/next/...` always exists at any tag as a fallback. |
| Canonical defaults | `herdr --default-config` (post-rebuild) / `nix run github:herdrdev/herdr/<tag>#herdr -- --default-config` (pre-rebuild) | Shipped default *values* — only for the keys the sample config shows. |
| Documented key surface | `https://raw.githubusercontent.com/herdrdev/herdr/refs/tags/<tag>/docs/next/website/src/data/config-reference.json` | Machine-readable `key`/`type`/`default`/`description` list; **superset** of `--default-config` (210 vs 133 keys at v0.9.3). The `.mdx` sibling is just a `<ConfigReference />` wrapper with no table — parse the JSON, not the mdx. |
| Changelog | `https://github.com/herdrdev/herdr/blob/master/CHANGELOG.md` + Releases page | Check **Added/Changed/Fixed** for deprecated `ui.agent_panel_scope` etc. |
| Local config | `chezmoi/dot_config/herdr/config.toml.tmpl` | Validate with the **target** version's binary: `nix run github:herdrdev/herdr/<tag>#herdr -- config check`. Pre-rebuild the installed `herdr` is the old version, so plain `herdr config check` validates the wrong version. |
| Installed version | `herdr --version` / `nix flake metadata --json \| jq '.locks.nodes.herdr'` | Cross-check after rebuild. |

## Target Files

| File | What to edit |
|------|-------------|
| `flake.nix` — `herdr.url` in the `inputs` block | `herdr.url = "github:herdrdev/herdr/<tag>";` — **migrate** `ogulcancelik` → `herdrdev` if present; replace tag |
| `flake.lock` | **Never edit manually** — regenerated via `nix flake lock --update-input herdr` |
| `chezmoi/dot_config/herdr/config.toml.tmpl` | Only if `herdr config check` warns; keep keybindings/themes, remove retired keys |

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
| Update flake | Edit `herdr.url` in `flake.nix`'s `inputs` block | `herdr.url = "github:herdrdev/herdr/<tag>";` |
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

Edit the `herdr.url` line in `flake.nix`'s `inputs` block:

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
- Keep `herdr.inputs.nixpkgs.follows = "nixpkgs-unstable-2611";` line untouched.
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
# validate with the TARGET version's binary — pre-rebuild the installed herdr is the old version
nix run github:herdrdev/herdr/<tag>#herdr -- config check
# expect: `config: ok` (exit 0)
# after the rebuild the same check runs from the installed binary:
herdr config check
```

Common outputs and fixes:

| Warning | Fix in `chezmoi/dot_config/herdr/config.toml.tmpl` |
|---------|-----------------------------------------------|
| `unknown key ui.agent_panel_scope` | Delete line — retired (v0.8.x silently ignores, but check flags it) |
| `unknown theme name ...` | Fix typo or revert to built-in theme (rose-pine, etc.) — `herdr config check` now errors on unknown themes since v0.8.2 |
| `unknown key ...` for renamed keys | Consult https://herdr.dev/docs/configuration/ — remove or rename |

If clean, no edit needed. If warnings, edit `chezmoi/dot_config/herdr/config.toml.tmpl` and re-run the target-version check until clean.

### Step 5b: Discover New / Unconfigured Settings & Keybinds (Advisory — Do Not Auto-Enable)

After the target-version `herdr config check` is clean, diff the *target version's* documented surface against `chezmoi/dot_config/herdr/config.toml.tmpl` and surface anything unconfigured. Do not auto-enable — surface only.

**Decision rule — explicit config means decided (per user preference 2026-08-26):**
- If a key **does not appear** in `config.toml.tmpl` (or the rendered `~/.config/herdr/config.toml`) at all → candidate to surface in primary "unconfigured" table.
- If a key **appears in any form** (`= ""`, `= []`, `= false`, `= 0`, `= true`, `= "value"`, etc.) → **never surface** — explicit config is respected. Treat as decided and skip forever. This covers your blanked keybinds (35 of them as of 2026-10-11) like `focus_pane_left = ""`, `switch_tab = ""`, etc., **and** your intentional `= false`/`true` overrides like `update.version_check = false`, `ui.prompt_new_tab_name = false`, `ui.toast.clipboard.enabled = true`, `ui.sound.enabled = false`. Do not re-surface these as "differs from default".
- **No secondary table** — never surface a "differs from default" table. When you explicitly set `version_check = false` where default is `true`, that is respected, not advisory.

This ensures future you is not re-asked about anything you deliberately configured. For a new upstream key you haven't decided yet (e.g. `keys.move_tab_next` absent in your file), it surfaces **once**; if you then add `keys.move_tab_next = ""` to record "keep disabled" (or any explicit value), it is suppressed on all future bumps.

**1. Resolve docs URL for the target tag — the `<VER>` dir may not exist (verified 2026-10-11: at tag `v0.9.3` the newest `docs/versions/*` is `0.9.1`):**
```bash
TAG=v0.9.3  # from Step 2
# newest docs/versions/<VER> dir present at that tag — it lags the tag
DOCVER=$(gh api "repos/herdrdev/herdr/git/trees/${TAG}?recursive=1" --jq '.tree[].path' \
  | grep -oE '^docs/versions/[0-9.]+$' | sed 's|docs/versions/||' | sort -V | tail -1)
curl -fsSL "https://raw.githubusercontent.com/herdrdev/herdr/refs/tags/${TAG}/docs/versions/${DOCVER}/website/src/content/docs/configuration.mdx" -o /tmp/herdr-config-docs.mdx
# always-present fallback at any tag:
curl -fsSL "https://raw.githubusercontent.com/herdrdev/herdr/refs/tags/${TAG}/docs/next/website/src/content/docs/configuration.mdx" -o /tmp/herdr-config-docs.mdx
# in-agent preferred: web_fetch(url) for markdown
```
Also filter `CHANGELOG.md` at same ref for `### Added` since last pin to prioritize new keys.

**2. Build the three key lists. Both sides of the diff must use the SAME dotted-path extractor — a bare-key scan on one side makes every dotted key look unconfigured.**

**(a) Documented key surface for the tag — the authoritative list.** `docs/next/website/src/data/config-reference.json` = 210 keys at v0.9.3 against 134 in the sample config; it is a **superset** of `--default-config`, carrying legacy-but-accepted names (`keys.swap_pane_*`, `keys.copy_mode`, `experimental.kitty_graphics`) and the full `theme.custom.*` token set:
```bash
gh api "repos/herdrdev/herdr/contents/docs/next/website/src/data/config-reference.json?ref=${TAG}" --jq .content | base64 -d > /tmp/herdr.config-reference.json
jq -r 'def collect(p;n): (n.keys // [])[] | .key as $k | "\(p)\($k)", (collect("\(p)\($k)."; .)); [ .sections[] | collect(""; .) ] | unique[]' /tmp/herdr.config-reference.json | sort -u > /tmp/documented_keys.txt
```

**(b) Local keys, and (c) shipped default values.** One table-tracking extractor emits dotted paths, and also emits a table path when that table is present with no keys of its own — that is what lets an explicitly-empty `[table]` suppress its documented children:
```bash
cat > /tmp/dotted_keys.awk <<'AWK'
{ line=$0
  sub(/^[[:space:]]+/,"",line)
  if (line ~ /^#/) sub(/^#[[:space:]]*/,"",line)
  if (line ~ /^\[/) {
    if (tbl != "" && nkeys == 0) print tbl
    h=line; sub(/[[:space:]]*#.*/,"",h); gsub(/[][[:space:]]/,"",h)
    tbl=h; nkeys=0; next }
  if (line !~ /=/) next
  k=line; sub(/=.*/,"",k); gsub(/[[:space:]]/,"",k)
  v=line; sub(/^[^=]*=/,"",v); sub(/[[:space:]]*#.*/,"",v); gsub(/^[[:space:]]+|[[:space:]]+$/,"",v)
  if (k !~ /^[a-zA-Z_][a-zA-Z0-9_.-]*$/) next
  # value must be a complete TOML scalar or the opening of an array/inline table — a plain grep also matches
  # prose comments such as "# off = disable pop-up notifications" and "# type = \"shell\" runs detached..."
  ok = (v ~ /^\[/ || v ~ /^\{/ || v ~ /^"[^"]*"$/ || v ~ /^[0-9-][0-9]*$/ || v=="true" || v=="false" || v=="reset")
  if (!ok) next
  nkeys++
  print (tbl != "" ? tbl "." k : k) }
END { if (tbl != "" && nkeys == 0) print tbl }
AWK
awk -f /tmp/dotted_keys.awk chezmoi/dot_config/herdr/config.toml.tmpl | sort -u > /tmp/local_keys.txt
nix run github:herdrdev/herdr/${TAG}#herdr -- --default-config > /tmp/herdr.default.toml
awk -f /tmp/dotted_keys.awk /tmp/herdr.default.toml | sort -u > /tmp/default_keys.txt
```
```

**3. Diff → advisory table (primary only — no secondary):**
```bash
comm -23 /tmp/documented_keys.txt /tmp/local_keys.txt > /tmp/missing.txt   # documented but not configured here
# Drop decidable families, then children of tables that are present-but-childless (an explicitly-empty
# [table] states a documented default of {}, e.g. [ui.sidebar.agents.rows_by_agent]).
# Verified 2026-10-11: with the current config at v0.9.3 this leaves 0 candidates — fix any non-empty
# family that should have been caught rather than reporting it as new.
python3 - <<'PY' > /tmp/surface.txt
local = {l.strip() for l in open('/tmp/local_keys.txt') if l.strip()}
cand  = [l.strip() for l in open('/tmp/missing.txt') if l.strip()]
families = [   # (prefix to drop, keys that must be configured locally for that drop to apply)
    ('keys.indexed.',              ['keys.switch_tab', 'keys.focus_agent']),  # legacy; superseded
    ('experimental.kitty_graphics', ['terminal.kitty_graphics']),            # accepted legacy name
    ('theme.custom.',              ['theme.custom']),                        # token leaves; owning table set
    ('ui.sound.',                  ['ui.sound.enabled']),                    # moot while sounds are disabled
]
drop = [p for p, gates in families if all(g in local for g in gates)]
childless = {p for p in local if not any(q.startswith(p + '.') for q in local)}
for k in cand:
    if any(k.startswith(p) for p in drop): continue
    parent = k.rsplit('.', 1)[0]
    if parent != k and parent in childless: continue
    print(k)
PY
```
- **Primary "unconfigured"** = the contents of `/tmp/surface.txt`. A key present locally in *any* form (`= ""`, `= []`, `= false`, `= 0`, …) is already excluded, so explicit config is decided. Group by table for readability.
- **Legacy-but-accepted keys** — documented in the JSON but absent from `--default-config`. Drop them once the modern successor is configured, as the family filter above does; never report them as candidates.
- **No secondary table** — do not build or surface "differs from default" (e.g. `update.version_check = false` vs `true`, `ui.prompt_new_tab_name = false` vs `true`) — these are explicitly configured and respected per user preference 2026-08-26. Suppress entirely.
- **Do not parse `config-reference.mdx` at the raw URL** — verified 2026-08-26 it renders via `<ConfigReference />` and contains no key table. Its JSON sibling (`.../website/src/data/config-reference.json`) *is* the key list; parse that. Use `--default-config` for shipped default *values* and `configuration.mdx` only for human context.

Present as advisory via `socrates` (under the inbound+reversible autonomy path do not block on it — print the table, take "keep disabled" as the default, and continue to the stage step):

> "Target `v0.8.2` adds N unconfigured groups you haven't decided: [primary table]. Keep disabled, or pick any to stage? (no auto-enable — explicit config like `ui.toast.clipboard.enabled = true` is already respected and not re-surfaced)"

Example primary for `v0.9.0 → v0.9.3` with this repo's config (`v0.9.3` pinned, 35 `= ""` suppressed) — genuinely unconfigured: `keys.clear_pane` (new in v0.9.2, unbound by default), `session.startup_per_agent_delay_ms` (new in v0.9.2, default 100), `ui.accent`, `theme.name`, `ui.sidebar.agents.rows_by_agent.claude`. Decided/moot, do not surface: `ui.sound.*` (`ui.sound.enabled = false`), `keys.indexed.*` (legacy), `theme.custom.panel_bg` (token, table present). Historical example (`v0.8.0 → v0.8.2`): `ui.window_title`, `ui.pane_outer_borders`, `ui.status_indicators`, `ui.tab_bar_right`/`tab_bar_right_separator`/`tab_bar_position`, `ui.sidebar.agents.rows`/`row_gap`/`rows_by_agent`, `ui.sidebar.spaces.rows`, `keys.move_tab_previous`/`move_tab_next`, `keys.resize_pane_left/down/up/right`, `terminal.default_shell`/`shell_mode`, `server.headless_cols`/`headless_rows`, `remote.manage_ssh_config`.

**4. Stage only on opt-in:**
If user picks a key to enable, append it to `chezmoi/dot_config/herdr/config.toml.tmpl` commented with context and re-run `herdr config check`:
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
# if config.toml.tmpl changed:
git add chezmoi/dot_config/herdr/config.toml.tmpl
```

Provide user with ready-to-run commands (do not execute):

```bash
git commit -m "chore: update herdr to v0.9.3

migrate: ogulcancelik/herdr → herdrdev/herdr (canonical org)
herdr: v0.9.0 → v0.9.3 (rev 7b116c0)

Co-authored-by: herdr-maintainer"
sudo darwin-rebuild switch --flake $HOME/code/nixos-dotfiles#cyan
herdr --version
herdr config check
nix flake metadata --json | jq '.locks.nodes.herdr'
```

Commit message template:
- Title: `chore: update herdr to <tag>` (`v0.9.3` or `preview-...`)
- Body: org migration note if applicable, old→new tag, locked rev short-hash from `flake.lock`

## Verification Checklist

- [ ] `flake.nix` uses `herdrdev/herdr/<tag>` (not `ogulcancelik`)
- [ ] `flake.lock` `nodes.herdr.original.ref` == chosen tag
- [ ] `flake.lock` `nodes.herdr.locked.rev` is 40-char, `narHash` present
- [ ] `nix run github:herdrdev/herdr/<tag>#herdr -- config check` exits 0 with `config: ok` (target version, pre-rebuild)
- [ ] Unconfigured options from target `<VER>` docs surfaced (advisory, none auto-enabled; any explicit config — `= ""`/`= []`/`= false`/`= true`/`= "value"` — treated as decided and not re-surfaced; no secondary differs per 2026-08-26)
- [ ] After user runs `darwin-rebuild`, `herdr --version` matches the pinned tag

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
| Assuming `docs/versions/<VER>/` exists for the tag | It lags the tag (v0.9.3 → newest dir `0.9.1`). Resolve via `git/trees/<tag>?recursive=1`, or use `docs/next/...` |
| Running the installed `herdr config check` before rebuilding | It validates the *old* version. Use `nix run github:herdrdev/herdr/<tag>#herdr -- config check` |
| Treating `--default-config` as the full key list | It hides legacy-but-accepted keys and most `theme.custom.*` tokens. Use `docs/next/website/src/data/config-reference.json` |
