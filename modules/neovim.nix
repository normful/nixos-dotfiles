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
    environment.systemPackages = [
      (if config.my.enableFullNeovim then fullNeovim else pkgs-pinned-unstable.neovim)
    ]
    ++ (with pkgs-pinned-unstable; [
      # https://www.gnu.org/software/make/
      gnumake
    ]);
  };
}
