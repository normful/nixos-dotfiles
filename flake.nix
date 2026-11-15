{
  inputs = {
    # Previous stable
    nixpkgs-2511.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Current stable
    nixpkgs-2605.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Upcoming stable (currently unstable)
    # To get latest unstable commit, run:
    # git ls-remote https://github.com/NixOS/nixpkgs.git refs/heads/nixpkgs-unstable | cut -f1
    nixpkgs-unstable-2611.url = "github:NixOS/nixpkgs/4fe25e12eb9f4c744966dd3de5a05246cf098601";

    nix-darwin-2605.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin-2605.inputs.nixpkgs.follows = "nixpkgs-2605";

    nix-casks.url = "github:atahanyorganci/nix-casks/archive";
    nix-casks.inputs.nixpkgs.follows = "nixpkgs-2605";

    llm-agents.url = "github:numtide/llm-agents.nix";
    llm-agents.inputs.nixpkgs.follows = "nixpkgs-unstable-2611";

    herdr.url = "github:herdrdev/herdr/v0.9.5";
    herdr.inputs.nixpkgs.follows = "nixpkgs-unstable-2611";

    # uv2nix builds packages/swival: a uv-locked virtualenv for a Python project
    # whose 102-package runtime closure does not exist in nixpkgs at the pinned
    # versions. Revisions are pinned; update them with `nix flake update`.
    pyproject-nix.url = "github:pyproject-nix/pyproject.nix/d43f0e74444c1f266c640fc49ce6ce6fb69d33c3";
    pyproject-nix.inputs.nixpkgs.follows = "nixpkgs-unstable-2611";
    uv2nix.url = "github:pyproject-nix/uv2nix/c361746c7d630d98b972378290547c8d35542a7a";
    uv2nix.inputs.pyproject-nix.follows = "pyproject-nix";
    uv2nix.inputs.nixpkgs.follows = "nixpkgs-unstable-2611";
    pyproject-build-systems.url = "github:pyproject-nix/build-system-pkgs/bdbc5f8dd2ad6136bb2ccecb14f6ec343965b194";
    pyproject-build-systems.inputs.pyproject-nix.follows = "pyproject-nix";
    pyproject-build-systems.inputs.uv2nix.follows = "uv2nix";
  };

  outputs = inputs @ {
    nixpkgs-2511,
    nixpkgs-2605,
    nixpkgs-unstable-2611,
    ...
  }: let
    genAttrs = nixpkgs-2605.lib.genAttrs;
    darwinSystem2605 = inputs.nix-darwin-2605.lib.darwinSystem;

    # Load custom overlays from the overlays/ directory.
    # Each subdirectory there is an overlay (see overlays/default.nix).
    # Applying this overlay lets us use packages like hello-wrapped,
    # figlet-patched, etc. in system environment.systemPackages.
    myOverlays = import ./overlays {
      lib = nixpkgs-2605.lib;
    };
  in {
    # The only machine this flake configures. Everything here is load-bearing.
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
          overlays = [myOverlays];
        };
      };
    };

    # `nix fmt` runs the formatter with the flake root as its working
    # directory. Alejandra without arguments reads stdin, so wrap it to
    # default to the whole repository while still forwarding explicit paths.
    formatter = genAttrs ["aarch64-darwin" "x86_64-linux"] (
      system: let
        pkgs = nixpkgs-2605.legacyPackages.${system};
      in
        pkgs.writeShellApplication {
          name = "alejandra";
          runtimeInputs = [pkgs.alejandra];
          text = ''
            # `nix fmt` may pass flags only (e.g. `nix fmt -- --check`), which
            # would leave alejandra reading stdin. Default to the repository
            # in that case; honour an explicit `-` for stdin.
            have_path=false
            for arg in "$@"; do
              if [ "$arg" = "-" ]; then
                have_path=true
              else
                case "$arg" in
                  -*) ;;
                  *) have_path=true ;;
                esac
              fi
            done
            if [ "$have_path" = false ]; then
              set -- "$@" .
            fi
            exec alejandra "$@"
          '';
        }
    );
  };
}
