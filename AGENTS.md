# NixOS Dotfiles

Primary focus: **nix-darwin config for macOS (hostname: cyan)** and **neovim config**.

## Key Paths

- macOS config: `mac/cyan/configuration.nix`
- NixOS modules: `modules/`
- Neovim: `modules/neovim.nix`
- Chezmoi dotfiles: `chezmoi/`

## Chezmoi Source Naming

Prefixes are parsed **in a fixed order per target type**, and a name that breaks
that order is not an error: chezmoi stops parsing at the offending prefix and
treats the rest as a literal name. `private_modify_foo.tmpl` is therefore a
*plain template* named `modify_foo` that inherits `0600` — the script never runs
and nothing warns.

| Target | Prefixes, in order |
| ------ | ------------------ |
| Directory | `remove_`, `external_`, `exact_`, `private_`, `readonly_`, `dot_` |
| Regular file | `encrypted_`, `private_`, `readonly_`, `empty_`, `executable_`, `dot_` |
| Create file | `create_` + the regular-file list |
| Modify file | `modify_` + the regular-file list, minus `empty_` |
| Remove file / symlink | `remove_`, `dot_` / `symlink_`, `dot_` |
| Script | `run_`, then `once_` or `onchange_`, then `before_` or `after_` |

`.tmpl` is a suffix and applies last. `chezmoi source-path <target under $HOME>`
is the check: a mis-ordered name resolves to a target you did not mean, or the
one you meant reports `not managed`. The same rule governs the private source
(`~/code/private-dotfiles`), which is where this was found. Reference:
<https://www.chezmoi.io/reference/source-state-attributes/>

## Off-Limits (unless explicitly asked)

- `.git`, `wsl/`, `.venv/`, `node_modules/`
- README.md, LICENSE

## Git Workflow

- **Committing and pushing directly to `main` is allowed in this repo.**
  Norman (the repo owner) has explicitly authorized it. Agents do not need to
  create a feature branch for routine work here unless Norman asks for one.
- Never `git push --force` / `--force-with-lease` to any branch.
- Skill-specific commit policies still apply where they exist (e.g. the
  `maintain-tokscale-models-custom-pricing` skill says routine pricing runs
  leave changes uncommitted unless Norman says to commit).

## Formatting

- Nix files use [alejandra](https://github.com/kamadorueda/alejandra), exposed via
  `flake.nix`'s `formatter` output (from the `nixpkgs-2605` pin).
- Format the whole repo: `nix fmt -- .` (alejandra with no arguments reads stdin,
  so pass the path explicitly).
- Check without writing: `alejandra --check <files>`.

## Flake Maintenance

### Updating nixpkgs-unstable

To update the pinned unstable input:

1. Get the latest commit hash:
   `git ls-remote https://github.com/NixOS/nixpkgs.git refs/heads/nixpkgs-unstable | cut -f1`
2. Update the commit hash in the `nixpkgs-unstable-2611.url` in `flake.nix`
3. Run: `nix flake lock --update-input nixpkgs-unstable-2611`
4. **NEVER** manually edit `flake.lock` — always use the `nix flake lock` command

## Neovim Config Organization

### Layer 1: Nix Integration (`modules/neovim.nix`)

- Configures neovim build with Python3, NodeJS, Ruby support
- Installs language tooling (luajit, stylua, tree-sitter, deno, cargo, go, php, python, gcc)
- Points to `packages/neovim/` for vimrc

### Layer 2: Bootstrap (`packages/neovim/`)

- `initLazyAndNvChad.lua` - Bootstraps lazy.nvim plugin manager, loads NvChad v2.5, imports plugin specs

### Layer 3: Core Config (`chezmoi/dot_config/nvim/lua/`)

| File | Purpose |
|------|---------|
| `chadrc.lua` | NvChad theme/ui overrides |
| `lazy-config.lua` | lazy.nvim settings |
| `options.lua` | Vim options |
| `mappings.lua` | Keybindings |
| `user-commands.lua` | Custom : commands |
| `lsp-on-attach.lua` | LSP attach callbacks |
| `augroups.lua.tmpl` | Autocommands (chezmoi template) |
| `neovide.lua` | Neovide GUI settings |
| `directory-watcher.lua` | Auto-refresh when dir changes |
| `hotreload.lua` | Live config reload |


### Layer 5: Plugin Configs (`chezmoi/dot_config/nvim/lua/plugins/`)

- Individual plugin spec files in lazy.nvim format
- Naming: `plugin-name.lua` (e.g., `telescope.lua`, `treesitter.lua`)
- Each file returns a lazy.nvim plugin spec table

## Local Skills (`.pi/skills/`)

| Skill | Description |
|-------|-------------|
| [maintain-herdr](.pi/skills/maintain-herdr/SKILL.md) | Maintain and upgrade herdr pin in flake.nix/flake.lock plus config.toml compatibility |
| [maintain-rpiv-pi-models](.pi/skills/maintain-rpiv-pi-models/SKILL.md) | Maintain models used for rpiv-pi skills and agents (`private_models.json`) |
| [maintain-terminal-configs](.pi/skills/maintain-terminal-configs/SKILL.md) | Maintain synchronized keybindings across Ghostty, WezTerm, and Kitty |
| [maintain-tokscale-models-custom-pricing](.pi/skills/maintain-tokscale-models-custom-pricing/SKILL.md) | Maintain tokscale custom pricing for aihubmix models (`custom-pricing.json`) |
| [update-nixpkgs-unstable](.pi/skills/update-nixpkgs-unstable/SKILL.md) | Update nixpkgs-unstable reference in flake.nix to latest commit |
| [update-pi-model-overrides](.pi/skills/update-pi-model-overrides/SKILL.md) | Update OpenCode Go model rate limits and availability in `models.json` |
