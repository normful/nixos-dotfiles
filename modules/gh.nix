{
  config,
  pkgs-stable,
  ...
}:
{
  environment.systemPackages = with pkgs-stable; [
    (callPackage ../packages/gh-wrapped { inherit config; })
  ];

  sops.secrets = {
    githubClassicPersonalAccessToken = {
      owner = config.my.user.name;
      group = "users";
    };
  };
}