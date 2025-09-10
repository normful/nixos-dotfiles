{
  pkgs-stable,
  config,
  lib,
  ...
}:
{
  programs.nh = {
    enable = true;
    flake = "/etc/nixos";
  };

  environment.systemPackages = with pkgs-stable; [
    nix-output-monitor
    nvd
  ];
}
