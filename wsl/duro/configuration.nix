{
  inputs,
  ...
}:
{
  imports = [
    inputs.nixos-wsl-2505.nixosModules.default
    ../../modules/overall-options.nix
    ../../modules/interactive-cli.nix
    ./my-config.nix
  ];
}
