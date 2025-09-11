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

  security.polkit = {
    enable = true;
    # Allow members of the wheel group to shutdown/reboot without password
    extraConfig = ''
      polkit.addRule(function(action, subject) {
          if (
              subject.isInGroup("wheel") && (
                  action.id == "org.freedesktop.login1.reboot" ||
                  action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
                  action.id == "org.freedesktop.login1.power-off" ||
                  action.id == "org.freedesktop.login1.power-off-multiple-sessions"
              )
          )
          {
              return polkit.Result.YES;
          }
      });
    '';
  };
}
