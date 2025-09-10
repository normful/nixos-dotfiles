function mm --description 'Build and switch nix-darwin config for the cyan macOS system'
    pushd ~/code/nixos-dotfiles
    mise cyan
    popd
end
