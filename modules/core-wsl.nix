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

  programs.fish.enable = true;

  users.users.${config.my.user.name} = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [ "wheel" ];
    shell = pkgs-stable.fish;
  };
}
