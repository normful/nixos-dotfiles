# nixos-dotfiles

Dotfiles and configuration for macOS+[nix-darwin](https://github.com/LnL7/nix-darwin) and [NixOS](https://nixos.org).

To keep things simple, I'm purposely not using
[home-manager](https://github.com/nix-community/home-manager). Instead, I'm using [GNU
Stow](https://github.com/aspiers/stow) to symlink dotfiles into `$HOME` instead.

## Typical Usage

### macOS (nix-darwin)

```sh
nix fmt
make mac
make stow
```

### NixOS

```sh
sudo nixos-rebuild switch --flake .#lilac
make stow
```

## Some manual steps needed on macOS

### Changing Shell to Fish

```sh
sudo rm /etc/shells
make mac
chsh -s /run/current-system/sw/bin/fish
```

Note that after an upgrade of macOS, `/etc/shells` may be recreated by macOS, so you'll need to delete it again.

## Why I don't run NixOS in a VM on a macOS host

Previously, I tried running NixOS in a VM in VMWare Fusion and Parallels. Although
that worked, I realized that I prefer the simplicity of running Nix directly on
my macOS host. It seems like there's too many constant bugs and workarounds needed
to make Parallels Tools or VMWare Tools properly.

## Neovim Config

1. `./nix-nvim/customRC.vim.nix` is the `.vimrc` file that Nix generates. It loads general lua modules, and loads:
2. `./nix-nvim/initLazyAndNvChad.lua`, which initializes [lazy.nvim](https://github.com/folke/lazy.nvim) and [NvChad](https://github.com/NvChad/NvChad)

The rest of the Neovim config, which is in `./nvim`, is not managed by Nix.

It's purposely not controlled by Nix, so that it can be easily reused on
other systems that are not running Nix (e.g. other macOS systems
where I don't run Nix, or other Linux systems).

`./nvim/.config/nvim` is symlinked into `~/.config/nvim` using `stow`.

`lazy.nvim` automatically loads all the plugin config from ~/.config/nvim/lua/plugins/`.
Plugin config extends any config provided by [NvChad plugin config](https://github.com/NvChad/NvChad/tree/v2.5/lua/nvchad/plugins).

There's a handful of miscellaneous old unused nvim config in `./nvim_OLD` that I don't use anymore.
