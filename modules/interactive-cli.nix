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
      ]
      ++ (with pkgs-pinned-unstable; [
        nix-output-monitor
        nvd
        chezmoi
        mise
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
