{ pkgs-pinned-unstable, ... }:
{
  my.user.name = "norman";
  my.hostname = "duro";

  my.enableInteractiveCli = true;
  my.enableFullNeovim = true;
  my.enableAiCodingAgents = true;
  my.enableLangTsJs = true;
  my.enableLangGo = true;
  my.enableLangPython = true;
  my.enableLangBash = true;
  my.enableLangCss = true;
  my.enableLangPhp = true;
  my.enableLangTypst = true;
  my.enableDocker = true;
  my.enableNetworkingTools = true;
  my.enableFileSyncTools = true;
  my.enableLogTools = true;
  my.enableConfigLangsTools = true;
  my.enableGitTools = true;
  my.enableSqlDbTools = true;

  environment.systemPackages = [
    pkgs-pinned-unstable.mariadb_118
  ];

  system.stateVersion = "25.05"; # Don't change this after initial installation
}
