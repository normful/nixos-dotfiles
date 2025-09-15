{
  pkgs-stable,
  config,
  ...
}:
{
  wsl.enable = true;
  wsl.defaultUser = config.my.user.name;
  wsl.docker-desktop.enable = true;

  networking.hostName = config.my.hostname;
  environment.systemPackages = with pkgs-stable; [
    curl
    git
    sops
    age
  ];
}
