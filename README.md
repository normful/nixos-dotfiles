# nixos-dotfiles
Personal NixOS configuration and dotfiles

## Some manual steps needed on macOS

### Changing Shell to Fish

```
sudo rm /etc/shells
make mac
chsh -s /run/current-system/sw/bin/fish
```
