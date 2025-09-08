{ pkgs-stable, ... }:
let
  substituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
  ];
in
{
  nix.package = pkgs-stable.nixVersions.latest;

  nix.settings = {
    auto-optimise-store = true;
    keep-derivations = false;
    keep-failed = false;
    keep-going = true;
    keep-outputs = false;
    min-free = 10 * 1024 * 1024 * 1024;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    builders-use-substitutes = true;
    substituters = substituters;
    trusted-substituters = substituters;
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 1h";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "daily" ];
  };

  nixpkgs.config.allowUnfree = true;
}
