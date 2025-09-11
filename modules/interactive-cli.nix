{
  config,
  pkgs-stable,
  pkgs-pinned-unstable,
  ...
}:
{
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

}
