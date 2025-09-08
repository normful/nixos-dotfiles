{
  pkgs-stable,
  config,
  lib,
  ...
}:
{
  programs.nh = lib.mkIf config.my.bigInstall {
    enable = true;
    flake = "/etc/nixos";
  };

  environment.systemPackages = lib.mkIf config.my.bigInstall (with pkgs-stable; [
    nix-output-monitor
    nvd
  ]);
}
