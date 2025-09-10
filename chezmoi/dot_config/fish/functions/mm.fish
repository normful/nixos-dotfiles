function mm --description 'Build and switch nix-darwin config for this mac'
    pushd ~/code/nixos-dotfiles
    make mac
    popd
end
