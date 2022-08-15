# nixos-dotfiles

Dotfiles and configuration for NixOS and
macOS+[Nix](https://nixos.org/manual/nix/stable/installation/multi-user.html)+[nix-darwin](https://github.com/LnL7/nix-darwin).

To keep things simple, I'm purposely not using
[home-manager](https://github.com/nix-community/home-manager). Instead, I'm using [GNU
Stow](https://github.com/aspiers/stow) to symlink dotfiles into `$HOME` instead.

## Typical Usage

```
make mac
make stow
```

## Some manual steps needed on macOS

### Changing Shell to Fish

```
sudo rm /etc/shells
make mac
chsh -s /run/current-system/sw/bin/fish
```

## Why I don't run NixOS in a VM on a macOS host

Previously, I tried running NixOS in a VM in VMWare Fusion and Parallels. Although
that worked, I realized that I prefer the simplicity of running Nix directly on
my macOS host. It seems like there's too many constant bugs and workarounds needed
to make Parallels Tools or VMWare Tools properly. So there are some left over
config files for that setup here too, but I don't use them anymore.

## Neovim Config

I'm not symlinking Neovim config into `$HOME/.config/nvim` because I couldn't
get treesitter to work that way.

I couldn't figure out how to get `require` in lua files to work with my custon
lua files, when used with the Nixpkgs [neovim derivation](https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/neovim/default.nix).

So I'm just inserting all my lua inline in a generated `.vimrc` [file](https://github.com/normful/nixos-dotfiles/blob/main/nvim/vimrc.nix).

My `nvim` config is in the process of being migrated from a modular
Packer-based set of lua files. [These](https://github.com/normful/nixos-dotfiles/tree/main/nvim/lua/todo)
are all the files that I haven't migrated yet.
