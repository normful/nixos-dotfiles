{
  inputs = {
    nixpkgs-2411.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-2505.url = "github:NixOS/nixpkgs/nixos-25.05";

    # To get latest unstable commit, run:
    # git ls-remote https://github.com/NixOS/nixpkgs.git refs/heads/nixpkgs-unstable | cut -f1
    nixpkgs-unstable-2511.url = "github:NixOS/nixpkgs/aca2499b79170038df0dbaec8bf2f689b506ad32";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs-2411";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs-2411";

    nix-darwin.url = "github:nix-darwin/nix-darwin/15f067638e2887c58c4b6ba1bdb65a0b61dc58c5";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-unstable-2511";
  };

  outputs =
    inputs@{
      nixpkgs-2411,
      nixpkgs-2505,
      nixpkgs-unstable-2511,
      ...
    }:
    let
      genAttrs = nixpkgs-2411.lib.genAttrs;
      nixosSystem = nixpkgs-2411.lib.nixosSystem;
      darwinSystem = inputs.nix-darwin.lib.darwinSystem;

      linuxHostnames = [
        "coral"
      ];

      vmConfigs = genAttrs linuxHostnames (name: {
        system = "x86_64-linux";
      });

      createGcpConfig =
        hostname:
        let
          vmConfig = vmConfigs.${hostname};
        in
        nixosSystem rec {
          system = vmConfig.system;
          specialArgs = {
            inherit inputs;
            pkgs-stable = import nixpkgs-2411 {
              inherit system;
              config.allowUnfree = true;
            };
            pkgs-pinned-unstable = import nixpkgs-unstable-2511 {
              inherit system;
              config.allowUnfree = true;
            };
          };
          modules = [
            ./gcp/${hostname}/configuration.nix
          ];
        };
    in
    {
      nixosConfigurations = genAttrs (builtins.attrNames vmConfigs) createGcpConfig;

      darwinConfigurations.cyan = darwinSystem rec {
        system = "aarch64-darwin";
        modules = [
          ./macbook-pro-18-3-config.nix
        ];
        specialArgs = {
          inherit inputs;
          pkgs-stable = import nixpkgs-2505 {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-pinned-unstable = import nixpkgs-unstable-2511 {
            inherit system;
            config.allowUnfree = true;
          };
        };
      };

      formatter = genAttrs [ "aarch64-darwin" "x86_64-linux" ] (
        system: nixpkgs-2505.legacyPackages.${system}.nixfmt-rfc-style
      );
    };
}
