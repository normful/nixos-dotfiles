{ pkgs, nixpkgs }:

{
  # See https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/neovim/utils.nix

  customRC = pkgs.callPackage ./customRC.vim.nix {};
}
