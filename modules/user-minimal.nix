# duro-only (legacy WSL host, not in use): not imported by cyan.
{
  pkgs-stable,
  config,
  ...
}: {
  programs.fish.enable = true;
  users.users.${config.my.user.name} = {
    isNormalUser = true;
    createHome = true;
    extraGroups = ["wheel"];
    shell = pkgs-stable.fish;
  };
}
