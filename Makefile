stow:
	stow -t $(HOME) -S git fish kitty karabiner htop scripts

unstow:
	stow -t $(HOME) -D git fish kitty karabiner htop scripts

mac:
	darwin-rebuild switch --flake ~/code/nixos-dotfiles#macbook-pro-18-3

update-flake:
	nix flake update
