{
  inputs,
  ...
}:
{
  imports = [
    ./configuration.nix
    ../../modules/install-mode.nix
  ];

  my.isFirstInstall = true;
}