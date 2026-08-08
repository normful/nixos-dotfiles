{
  inputs = {
    # Previous stable
    nixpkgs-2511.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Current stable
    nixpkgs-2605.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Upcoming stable (currently unstable)
    # To get latest unstable commit, run:
    # git ls-remote https://github.com/NixOS/nixpkgs.git refs/heads/nixpkgs-unstable | cut -f1
    nixpkgs-unstable-2611.url = "github:NixOS/nixpkgs/f205b5574fd0cb7da5b702a2da51507b7f4fdd1b";

    nix-darwin-2605.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin-2605.inputs.nixpkgs.follows = "nixpkgs-2605";

    nixos-wsl-2605.url = "github:nix-community/nixos-wsl/release-26.05";
    nixos-wsl-2605.inputs.nixpkgs.follows = "nixpkgs-2605";

    nix-casks.url = "github:atahanyorganci/nix-casks/archive";
    nix-casks.inputs.nixpkgs.follows = "nixpkgs-2605";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs-2605";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs-2605";

    llm-agents.url = "github:numtide/llm-agents.nix";
    llm-agents.inputs.nixpkgs.follows = "nixpkgs-unstable-2611";

    herdr.url = "github:ogulcancelik/herdr/v0.8.0";
    herdr.inputs.nixpkgs.follows = "nixpkgs-unstable-2611";
  };

  outputs =
    inputs@{
      nixpkgs-2511,
      nixpkgs-2605,
      nixpkgs-unstable-2611,
      ...
    }:
    let
      genAttrs = nixpkgs-2605.lib.genAttrs;
      nixosSystem2605 = nixpkgs-2605.lib.nixosSystem;
      darwinSystem2605 = inputs.nix-darwin-2605.lib.darwinSystem;

      # Load custom overlays from the overlays/ directory.
      # Each subdirectory there is an overlay (see overlays/default.nix).
      # Applying this overlay lets us use packages like hello-wrapped,
      # figlet-patched, etc. in system environment.systemPackages.
      myOverlays = import ./overlays {
        lib = nixpkgs-2605.lib;
      };

      createGcpConfig =
        hostname: configFile:
        nixosSystem2605 rec {
          system = "x86_64-linux";
          modules = [
            ./gcp/${hostname}/${configFile}
          ];
          specialArgs = {
            inherit inputs;
            pkgs-stable = import nixpkgs-2605 {
              inherit system;
              config.allowUnfree = true;
            };
            pkgs-pinned-unstable = import nixpkgs-unstable-2611 {
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
        duro = nixosSystem2605 rec {
          system = "x86_64-linux";
          modules = [
            ./wsl/duro/configuration.nix
          ];
          specialArgs = {
            inherit inputs;
            pkgs-stable = import nixpkgs-2605 {
              inherit system;
              config.allowUnfree = true;
            };
            pkgs-pinned-unstable = import nixpkgs-unstable-2611 {
              inherit system;
              config.allowUnfree = true;
            };
          };
        };
      };

      # Nix on macOS using nix-darwin
      darwinConfigurations.cyan = darwinSystem2605 rec {
        system = "aarch64-darwin";
        modules = [
          ./mac/cyan/configuration.nix
        ];
        specialArgs = {
          inherit inputs;
          pkgs-previous-stable = import nixpkgs-2511 {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-stable = import nixpkgs-2605 {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-pinned-unstable = import nixpkgs-unstable-2611 {
            inherit system;
            config = {
              allowUnfree = true;
              problems.handlers = {
                pysilero-vad.broken = "ignore";
              };
            };
            # Apply custom overlays so overlay-defined packages (hello-wrapped,
            # figlet-patched, etc.) are available in pkgs-pinned-unstable.
            overlays = [ myOverlays ];
          };
        };
      };

      formatter = genAttrs [ "aarch64-darwin" "x86_64-linux" ] (
        system: nixpkgs-2605.packages.${system}.nixfmt
      );
    };
}
