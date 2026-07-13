# NixOS Dotfiles

Primary focus: **nix-darwin config for macOS (hostname: cyan)** and **neovim config**.

## Key Paths

- macOS config: `mac/cyan/configuration.nix`
- NixOS modules: `modules/`
- Neovim: `modules/neovim.nix`
- Chezmoi dotfiles: `chezmoi/`

## Off-Limits (unless explicitly asked)

- `.git`, `gcp/`, `wsl/`, `secrets/`, `.venv/`, `node_modules/`
- Pulumi files, README.md, LICENSE, .sops.yaml

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
