{
  description = "My nix-darwin flake";

  inputs = {
    # Docs: https://github.com/NixOS/nix/blob/master/src/nix/flake.md#flake-references

    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-pinned-unstable.url = "github:NixOS/nixpkgs/388129ef194a9898401d9e9f9453d0945b1a0d85";

    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-stable";
  };

  outputs =
    {
      self,
      nixpkgs-stable,
      nixpkgs-pinned-unstable,
      nix-darwin,
    }:
    {
      darwinConfigurations.macbook-pro-18-3 = nix-darwin.lib.darwinSystem rec {
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
      formatter.aarch64-darwin = nixpkgs-stable.legacyPackages.aarch64-darwin.nixfmt-rfc-style;
    };
}
