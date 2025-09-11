{
  config,
  lib,
  pkgs-stable,
  ...
}:
let
  isDarwin = pkgs-stable.stdenv.isDarwin;
in
{
  options.my = {
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "The hostname to use for this machine.";
    };

    user.name = lib.mkOption {
      type = lib.types.str;
      description = "The name of the primary non-root user.";
    };

    isFirstInstall = lib.mkOption {
      type = lib.types.bool;
      description = "Whether this is the first installation of the system";
      default = false;
    };

    flakePath = lib.mkOption {
      description = "Path to the system flake";
      type = lib.types.str;
      default =
        if isDarwin then
          "/Users/${config.my.user.name}/code/nixos-dotfiles"
        else if config.my.isFirstInstall then
          "/etc/nixos"
        else
          "/home/${config.my.user.name}/code/nixos-dotfiles";
    };

    enableInteractiveCli = lib.mkOption {
      type = lib.types.bool;
      description = "Enable tools for interactive command line interface usage";
      default = false;
    };

    enableFullNeovim = lib.mkOption {
      type = lib.types.bool;
      description = "Install Neovim configured with many extras";
      default = false;
    };
  };
}
