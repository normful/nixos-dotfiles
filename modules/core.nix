{
  config,
  modulesPath,
  lib,
  pkgs-stable,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  options.my = {
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "The hostname to use for this machine.";
    };

    isFirstInstall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this is the first installation of the system";
    };

    flakePath = lib.mkOption {
      description = "Path to the system flake";
      type = lib.types.str;
      default =
        if config.my.isFirstInstall then
          "/etc/nixos"
        else
          "/home/${config.my.user.name}/code/nixos-dotfiles";
    };

    enableInteractiveCli = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable tools for interactive command line interface usage";
    };
  };

  config = {
    networking.hostName = config.my.hostname;

    environment.systemPackages = with pkgs-stable; [
      curl
      git
      sops
      age
    ];

    sops = {
      defaultSopsFile = "${config.my.flakePath}/secrets/gcp_${config.my.hostname}.yaml";
      age.keyFile = "/root/.config/sops/age/keys.txt";
      validateSopsFiles = false;
    };

    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    time.timeZone = "UTC";
    i18n.defaultLocale = "en_US.UTF-8";
  };
}
