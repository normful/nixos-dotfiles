{
  config,
  lib,
  pkgs-stable,
  pkgs-pinned-unstable,
  ...
}:
{
  config = lib.mkIf config.my.enableInteractiveCli {
    environment.systemPackages =
      with pkgs-stable;
      [
        chezmoi
        mise

        nix-output-monitor
        nvd
      ]
      ++ (with pkgs-pinned-unstable; [
        neovim
      ]);

    environment.variables = {
      EDITOR = "nvim";
      GIT_EDITOR = "nvim";
    };

    programs.nh = {
      enable = true;
      flake = config.my.flakePath;
    };
  };
}
