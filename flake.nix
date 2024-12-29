{
  description = "My nix-darwin flake";

  inputs = {
    # Docs: https://github.com/NixOS/nix/blob/master/src/nix/flake.md#flake-references

    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    nixpkgs-pinned-unstable.url = "github:NixOS/nixpkgs/30abd650aa5766f55513b4c56fca63df06b99baa";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs-stable";
  };

  outputs = {
      self,
      nixpkgs-stable,
      nixpkgs-pinned-unstable,
      darwin,
    }:
    {
      darwinConfigurations.macbook-pro-18-3 = darwin.lib.darwinSystem rec {
        system = "aarch64-darwin";
        modules = [
          ./macbook-pro-18-3-config.nix
        ];
        specialArgs = {
          nixpkgs-stable = nixpkgs-stable;
          nixpkgs-pinned-unstable = nixpkgs-pinned-unstable;
          pkgs-stable = import nixpkgs-stable {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-pinned-unstable = import nixpkgs-pinned-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        };
      };
    };
}
