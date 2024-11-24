{
  description = "My nix-darwin flake";

  inputs = {
    # Docs: https://github.com/NixOS/nix/blob/master/src/nix/flake.md#flake-references

    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
      self,
      nixpkgs,
      darwin,
    }: 
    {
      darwinConfigurations.macbook-pro-18-3 = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./macbook-pro-18-3-config.nix
        ];
        specialArgs = {
          inherit nixpkgs darwin;
        };
      };
    };
}
