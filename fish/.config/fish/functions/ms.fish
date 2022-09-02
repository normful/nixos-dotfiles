function ms --description "Run make target that creates symlinks from the home directory to my dotfiles"
    pushd ~/code/nixos-dotfiles
    find . -name .DS_Store -delete
    make stow
    popd
end
