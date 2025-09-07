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
        neovim
        sops
        age
        kitty
	rustup
      ]
      ++ (with pkgs-pinned-unstable; [ ]);

    sops = {
      defaultSopsFile = "/etc/nixos/secrets/gcp_${config.my.hostname}.yaml";
      age.keyFile = "/root/.config/sops/age/keys.txt";
      validateSopsFiles = false;
    };

    environment.variables = {
      EDITOR = "nvim";
      GIT_EDITOR = "nvim";
    };

    time.timeZone = "UTC";
    i18n.defaultLocale = "en_US.UTF-8";
  };
}
