{
  config,
  modulesPath,
  lib,
  pkgs-pinned-unstable,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  config = {
    networking.hostName = config.my.hostname;

    environment.systemPackages = with pkgs-pinned-unstable; [
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
  };
}
