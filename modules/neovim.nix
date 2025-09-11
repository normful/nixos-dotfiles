{
  config,
  pkgs-pinned-unstable,
  ...
}:

let
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
          lua5_4_compat
          lua54Packages.luarocks
          deno
          stylua
          gcc
          gnumake
          go
          tree-sitter
          unzip
          wget
          python314
          cargo
          php
          php84Packages.composer
        ])
      else
        [ pkgs-pinned-unstable.neovim ];
  };
}
