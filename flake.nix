{
  description = "My nix-darwin flake";

  inputs = {
    # Docs: https://github.com/NixOS/nix/blob/master/src/nix/flake.md#flake-references

    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-22.05-darwin";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs = {
      self,
      nixpkgs,
      nixpkgs-unstable,
      darwin,
    }: 
    {
      darwinConfigurations.macbook-pro-18-3 = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./macbook-pro-18-3-config.nix
        ];
        specialArgs = {
          inherit nixpkgs nixpkgs-unstable darwin;
        };
      };
    };
}
