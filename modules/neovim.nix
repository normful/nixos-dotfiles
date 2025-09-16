{
  config,
  lib,
  pkgs-pinned-unstable,
  ...
}:

let
  optionals = lib.optionals;
  fullNeovim = pkgs-pinned-unstable.neovim.override {
    # See https://github.com/NixOS/nixpkgs/blob/a0dfb2256cd7d89ce14c214017e6107c866469d4/pkgs/applications/editors/neovim/wrapper.nix

    withPython3 = true;
    withNodeJs = true;
    withRuby = true;

    vimAlias = true;
    viAlias = true;

    configure = {
      customRC = pkgs-pinned-unstable.callPackage ../packages/neovim { };
    };
  };
in
{
  config = {
    environment.systemPackages =
      if config.my.enableFullNeovim then
        [ fullNeovim ]
        ++ (with pkgs-pinned-unstable; [
          luajit
          luajitPackages.luarocks
          stylua
          tree-sitter
        ])
        ++ (optionals (!config.my.enableLangTsJs) (with pkgs-pinned-unstable; [ deno ]))
        ++ (optionals (!config.my.enableLangRust) (with pkgs-pinned-unstable; [ cargo ]))
        ++ (optionals (!config.my.enableLangGo) (with pkgs-pinned-unstable; [ go ]))
        ++ (optionals (!config.my.enableLangPhp) (with pkgs-pinned-unstable; [
          php
          php84Packages.composer
        ]))
        ++ (optionals (!config.my.enableLangPython) (with pkgs-pinned-unstable; [
          python313
          python313Packages.pip
        ]))
        ++ (optionals (!config.my.enableLangC) (with pkgs-pinned-unstable; [
          gcc
          gnumake
        ]))
      else
        [ pkgs-pinned-unstable.neovim ];
  };
}
