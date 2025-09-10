{
  config,
  lib,
  pkgs-unstable,
  ...
}:

with lib;

{
  options.my.golang = {
    enable = mkEnableOption "Go development environment";
  };

  config = mkIf config.my.golang.enable {
    environment.systemPackages = with pkgs-unstable; [
      go
      gopls
      delve
      golangci-lint
      gotools
      protoc-gen-go
    ];

    # Optional: Set Go environment variables system-wide
    /*
      environment.variables = {
        GOPATH = "$HOME/go";
        GOBIN = "$HOME/go/bin";
      };
    */
  };
}
