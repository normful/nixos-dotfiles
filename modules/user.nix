{
  config,
  lib,
  pkgs-stable,
  ...
}:
{
  options = {
    my.user.name = lib.mkOption {
      type = lib.types.str;
      description = "The name of the primary non-root user.";
    };
    my.user.sshPublicKey = lib.mkOption {
      type = lib.types.str;
      description = "An SSH public key that is authorized to login to the primary non-root user.";
    };
  };

  config = {
    environment.systemPackages = with pkgs-stable; [
      openssh
    ];

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

    systemd.services.generate-user-ssh-keys = {
      description = "Generate SSH keypair for user ${config.my.user.name}";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = config.my.user.name;
        Group = "users";
        RemainAfterExit = true;
      };
      script = ''
        SSH_DIR="/home/${config.my.user.name}/.ssh"
        PRIVATE_KEY="$SSH_DIR/id_rsa"
        PUBLIC_KEY="$SSH_DIR/id_rsa.pub"

        # Create .ssh directory if it doesn't exist
        if [ ! -d "$SSH_DIR" ]; then
          echo "Creating SSH directory: $SSH_DIR"
          mkdir -p "$SSH_DIR"
          chmod 700 "$SSH_DIR"
        fi

        # Check if keypair already exists
        if [ -f "$PRIVATE_KEY" ] && [ -f "$PUBLIC_KEY" ]; then
          echo "SSH keypair already exists for ${config.my.user.name}, skipping generation"
          exit 0
        fi

        # Generate new SSH keypair
        echo "Generating SSH keypair for ${config.my.user.name}..."
        ${pkgs-stable.openssh}/bin/ssh-keygen \
          -t ed25519 \
          -f "$PRIVATE_KEY" \
          -N "" \
          -C "${config.my.user.name}@${config.my.hostname}"

        # Set correct permissions
        chmod 600 "$PRIVATE_KEY"
        chmod 644 "$PUBLIC_KEY"

        echo "SSH keypair generated successfully for ${config.my.user.name}"
      '';
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
