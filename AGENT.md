# AGENT.md

This repository provides configurations for both macOS (using nix-darwin) and NixOS systems through Nix flakes and GNU Stow for symlinking dotfiles into `$HOME`.

## Common Commands
### Building and Deploying
- `make mac` - Build and switch to nix-darwin configuration for macOS
- `sudo nixos-rebuild switch --flake .#lilac` - Build and switch to NixOS configuration
- `make stow` - Symlink all dotfiles into `$HOME` using GNU Stow
- `make unstow` - Remove symlinked dotfiles from `$HOME`

### Maintenance
- `nix fmt` - Format Nix code using nixfmt-rfc-style
- `make update-flake` - Update flake.lock to latest package versions


### Lua Formatting (for Neovim config)
- `stylua .` - Format Lua files using stylua (configured in stylua.toml)

## Architecture
### Nix Flake Structure
- `flake.nix` - Main flake file defining system configurations
- Two system configurations:
  - `macbook-pro-18-3` (aarch64-darwin) - macOS/nix-darwin config
  - `lilac` (x86_64-linux) - NixOS config
- Uses both stable and pinned unstable nixpkgs for flexibility
- Package lists defined in `packages.nix`
- System-specific configurations in `macbook-pro-18-3-config.nix` and `nixos-config.nix`

### Dotfiles Organization
Each application has its own directory containing configuration files:
- `git/`, `fish/`, `kitty/`, `ghostty/`, `wezterm/`, `karabiner/`, `htop/`, `procs/`, `bat/`, `nvim/`, `scripts/`, `yazi/`, `cargo/`, `helix/`, `lftp/`, `warp/`

### Neovim Configuration
- Two-part setup: Nix manages core Neovim and loads initial Lua
- `nix-nvim/customRC.vim.nix` - Nix-generated .vimrc
- `nix-nvim/initLazyAndNvChad.lua` - Initializes lazy.nvim and NvChad
- `nvim/` directory (symlinked to ~/.config/nvim) contains plugin configurations
- Uses NvChad v2.5 with lazy.nvim for plugin management
- Old unused config preserved in `nvim_OLD/`

### Package Management
- Packages split between stable and pinned unstable nixpkgs
- Neovim uses pinned unstable for latest features
- Most packages use stable for reliability
- `packages.nix` contains comprehensive package lists organized by category

## Development Workflow
1. Make configuration changes to relevant `.nix` files
2. Format with `nix fmt`
3. Test build with `make mac` (macOS) or `sudo nixos-rebuild switch --flake .#lilac` (NixOS)
4. Update dotfiles with `make stow`
5. For Neovim Lua changes, use `stylua .` to format

## Key Files
- `flake.nix` - Main system configuration entry point
- `packages.nix` - Package definitions
- `Makefile` - Common commands and shortcuts
- `stylua.toml` - Lua formatting configuration for Neovim