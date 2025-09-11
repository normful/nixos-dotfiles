{ pkgs, config, ... }:

pkgs.symlinkJoin {
  name = "gh-wrapped";
  paths = [ pkgs.gh ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/gh \
      --run 'export GH_TOKEN="$(cat ${config.sops.secrets.githubClassicPersonalAccessToken.path})"'
  '';
}