{
  description = "My NixOS flake";

  inputs.nixpkgsGitHubBranch.url = "github:NixOS/nixpkgs/22.05";

  outputs = allInputs@{ self, nixpkgs, ... }: {

    # Used with `nixos-rebuild --flake .#<hostname>`
    nixosConfigurations.myConfig = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [ ./configuration.nix ];
      specialArgs = allInputs;
    };

    # Default overlay, for use in dependent flakes
    # overlay = final: prev: { };

    # # Same idea as overlay but a list or attrset of them.
    # overlays = { exampleOverlay = self.overlay; };
  };
}
