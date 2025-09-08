{
  config,
  modulesPath,
  lib,
  pkgs-stable,
  pkgs-pinned-unstable,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  options = {
    my.hostname = lib.mkOption {
      type = lib.types.str;
      description = "The hostname to use for this machine.";
    };
    my.bigInstall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to install a bigger set of packages.";
    };
  };

  config = {
    boot = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
    };

    networking.hostName = config.my.hostname;

    environment.systemPackages =
      with pkgs-stable;
      [
        curl
        git
        sops
        age
      ]
      ++ (with pkgs-pinned-unstable; [ ]);

    sops = {
      defaultSopsFile = "/etc/nixos/secrets/gcp_${config.my.hostname}.yaml";
      age.keyFile = "/root/.config/sops/age/keys.txt";
      validateSopsFiles = false;
    };

    environment.variables = lib.mkIf config.my.bigInstall {
      EDITOR = "nvim";
      GIT_EDITOR = "nvim";
    };

    time.timeZone = "UTC";
    i18n.defaultLocale = "en_US.UTF-8";
  };
}
