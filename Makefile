stow:
	stow --no-folding -t $(HOME) -S 'git' 'fish' 'kitty' 'ghostty' 'wezterm' 'karabiner' 'htop' 'procs' 'bat' 'nvim' 'scripts' 'yazi' 'cargo' 'helix' 'lftp' 'warp' 'claude'
unstow:
	stow --no-folding -t $(HOME) -D 'git' 'fish' 'kitty' 'ghostty' 'wezterm' 'karabiner' 'htop' 'procs' 'bat' 'nvim' 'scripts' 'yazi' 'cargo' 'helix' 'lftp' 'warp' 'claude'

mac:
	sudo darwin-rebuild switch --flake ~/code/nixos-dotfiles#macbook-pro-18-3

update-flake:
	nix flake update
