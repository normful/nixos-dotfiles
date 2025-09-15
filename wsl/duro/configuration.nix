{
  inputs,
  ...
}:
{
  imports = [
    ../../modules/overall-options.nix
    ./my-config.nix
    inputs.nixos-wsl-2505.nixosModules.default
    ../../modules/core-wsl.nix
    ../../modules/nix.nix
    ../../modules/user-ssh-keypair.nix
    ../../modules/interactive-cli.nix
    ../../modules/neovim.nix
    ../../modules/optional-packages-without-config.nix
  ];
}
