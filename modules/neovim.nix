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
          cargo
          deno
          gcc
          gnumake
          go
          luajit
          luajitPackages.luarocks
          php
          php84Packages.composer
          python313
          python313Packages.pip
          stylua
          tree-sitter
          unzip
          wget
        ])
      else
        [ pkgs-pinned-unstable.neovim ];
  };
}
