{
  config,
  lib,
  pkgs-stable,
  ...
}:
{
  options.my = {
    user.sshPublicKey = lib.mkOption {
      type = lib.types.str;
      description = "An SSH public key that is authorized to login to the primary non-root user.";
    };
  };

  config = {
    sops.secrets = {
      hashedUserPassword = {
        neededForUsers = true;
      };
    };

    programs.fish.enable = true;

    users.users.${config.my.user.name} = {
      description = "Main non-root user with sudo ability";
      isNormalUser = true;
      createHome = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ config.my.user.sshPublicKey ];
      shell = pkgs-stable.fish;
      hashedPasswordFile = config.sops.secrets.hashedUserPassword.path;
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
  };
}
