{
  pkgs-stable,
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
