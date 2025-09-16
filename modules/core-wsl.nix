{
  pkgs-pinned-unstable,
  config,
  ...
}:
{
  wsl.enable = true;
  wsl.defaultUser = config.my.user.name;
  wsl.docker-desktop.enable = true;

  networking.hostName = config.my.hostname;
  environment.systemPackages = with pkgs-pinned-unstable; [
    curl
  ];
}
