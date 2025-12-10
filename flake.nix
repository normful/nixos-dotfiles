{
  inputs = {
    nixpkgs-2511.url = "github:NixOS/nixpkgs/nixos-25.11";

    # To get latest unstable commit, run:
    # git ls-remote https://github.com/NixOS/nixpkgs.git refs/heads/nixpkgs-unstable | cut -f1
    nixpkgs-unstable-2605.url = "github:NixOS/nixpkgs/677fbe97984e7af3175b6c121f3c39ee5c8d62c9";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs-2511";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs-2511";

    nix-darwin-2511.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin-2511.inputs.nixpkgs.follows = "nixpkgs-2511";

    nix-casks.url = "github:atahanyorganci/nix-casks/archive";
    nix-casks.inputs.nixpkgs.follows = "nixpkgs-2511";

    nixos-wsl-2511.url = "github:nix-community/nixos-wsl/release-25.11";
    nixos-wsl-2511.inputs.nixpkgs.follows = "nixpkgs-2511";
  };

  outputs =
    inputs@{
      nixpkgs-2511,
      nixpkgs-unstable-2605,
      ...
    }:
    let
      genAttrs = nixpkgs-2511.lib.genAttrs;
      nixosSystem2511 = nixpkgs-2511.lib.nixosSystem;
      darwinSystem2511 = inputs.nix-darwin-2511.lib.darwinSystem;

      createGcpConfig =
        hostname: configFile:
        nixosSystem2511 rec {
          system = "x86_64-linux";
          modules = [
            ./gcp/${hostname}/${configFile}
          ];
          specialArgs = {
            inherit inputs;
            pkgs-stable = import nixpkgs-2511 {
              inherit system;
              config.allowUnfree = true;
            };
            pkgs-pinned-unstable = import nixpkgs-unstable-2605 {
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
        duro = nixosSystem2511 rec {
          system = "x86_64-linux";
          modules = [
            ./wsl/duro/configuration.nix
          ];
          specialArgs = {
            inherit inputs;
            pkgs-stable = import nixpkgs-2511 {
              inherit system;
              config.allowUnfree = true;
            };
            pkgs-pinned-unstable = import nixpkgs-unstable-2605 {
              inherit system;
              config.allowUnfree = true;
            };
          };
        };
      };

      # Nix on macOS using nix-darwin
      darwinConfigurations.cyan = darwinSystem2511 rec {
        system = "aarch64-darwin";
        modules = [
          ./mac/cyan/configuration.nix
        ];
        specialArgs = {
          inherit inputs;
          pkgs-stable = import nixpkgs-2511 {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-pinned-unstable = import nixpkgs-unstable-2605 {
            inherit system;
            config.allowUnfree = true;
          };
        };
      };

      formatter = genAttrs [ "aarch64-darwin" "x86_64-linux" ] (
        system: nixpkgs-2511.legacyPackages.${system}.nixfmt-rfc-style
      );
    };
}
