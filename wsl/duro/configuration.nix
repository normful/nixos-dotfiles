{
  inputs,
  ...
}:
{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    ../../modules/overall-options.nix
    ./my-config.nix
  ];
}
