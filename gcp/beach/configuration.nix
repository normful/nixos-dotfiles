{
  config,
  modulesPath,
  lib,

  inputs,
  pkgs-stable,
  pkgs-pinned-unstable,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    ../../shared-modules/disko-partitions.nix
    ../../shared-modules/core.nix
    ../../shared-modules/nix.nix
    ../../shared-modules/nh.nix
    ../../shared-modules/user.nix
    ../../shared-modules/openssh-server.nix
    ../../shared-modules/security.nix
    ../../shared-modules/tailscale.nix
    ./my-config.nix
  ];
}
