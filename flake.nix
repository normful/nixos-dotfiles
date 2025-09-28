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

    nixos-wsl-2505.url = "github:nix-community/nixos-wsl/release-25.05";
    nixos-wsl-2505.inputs.nixpkgs.follows = "nixpkgs-2505";
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
      nixosSystem2411 = nixpkgs-2411.lib.nixosSystem;
      nixosSystem2505 = nixpkgs-2505.lib.nixosSystem;
      darwinSystem = inputs.nix-darwin.lib.darwinSystem;

      gcpLinuxHostnames = [
        "jute"
      ];

      gcpVmConfigs = genAttrs gcpLinuxHostnames (name: {
        system = "x86_64-linux";
      });

      createGcpConfig =
        hostname: configFile:
        let
          vmConfig = gcpVmConfigs.${hostname};
        in
        nixosSystem2411 rec {
          system = vmConfig.system;
          modules = [
            ./gcp/${hostname}/${configFile}
          ];
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
        };
    in
    {
      nixosConfigurations = {
        # NixOS on Google Cloud Platform virtual machines
        jute = createGcpConfig "jute" "configuration.nix";
        jute-first-install = createGcpConfig "jute" "first-install-configuration.nix";

        # NixOS on Windows, in Windows Subsystem for Linux
        duro = nixosSystem2505 rec {
          system = "x86_64-linux";
          modules = [
            ./wsl/duro/configuration.nix
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
      };

      # Nix on macOS using nix-darwin
      darwinConfigurations.cyan = darwinSystem rec {
        system = "aarch64-darwin";
        modules = [
          ./mac/cyan/configuration.nix
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
