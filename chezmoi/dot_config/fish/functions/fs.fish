function fs --description 'Automatically save a new fish function file, after creating an alias'
    funcsave --directory ~/code/nixos-dotfiles/chezmoi/dot_config/fish/functions $argv
    ms
end
