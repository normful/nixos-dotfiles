{
  description = "My NixOS and nix-darwin flake";

  inputs = {
    # Docs: https://github.com/NixOS/nix/blob/master/src/nix/flake.md#flake-references

    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    # To get latest unstable commit, run:
    # git ls-remote https://github.com/NixOS/nixpkgs.git refs/heads/nixpkgs-unstable | cut -f1
    nixpkgs-pinned-unstable.url = "github:NixOS/nixpkgs/aca2499b79170038df0dbaec8bf2f689b506ad32";

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
      # nix-darwin configurations
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

      # Formatters for both systems
      formatter.aarch64-darwin = nixpkgs-stable.legacyPackages.aarch64-darwin.nixfmt-rfc-style;
      formatter.x86_64-linux = nixpkgs-stable.legacyPackages.x86_64-linux.nixfmt-rfc-style;
    };
}
