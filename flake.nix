{
  description = "My nix-darwin flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-22.05-darwin";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay/6e9964dd4a2198aeebef173807bcff1112cca45f";
  };

  outputs = {
      self,
      nixpkgs,
      nixpkgs-unstable,
      darwin,
      neovim-nightly-overlay
    }: 
    {
      darwinConfigurations.macbook-pro-18-3 = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./macbook-pro-18-3-config.nix
        ];
        specialArgs = {
          inherit nixpkgs nixpkgs-unstable darwin neovim-nightly-overlay;
        };
      };
    };
}
