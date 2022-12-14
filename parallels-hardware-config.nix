{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "usbhid" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  networking.interfaces.enp0s5.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  hardware.parallels.enable = true;

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "prl-tools" ];
}
