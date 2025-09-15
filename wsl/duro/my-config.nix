{ ... }:
{
  wsl.enable = true;
  wsl.defaultUser = "norman";

  system.stateVersion = "25.05"; # Don't change this after initial installation

  my.user.name = "norman";
  my.enableInteractiveCli = true;
}
