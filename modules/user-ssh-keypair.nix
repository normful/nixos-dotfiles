{
  config,
  pkgs-stable,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs-stable; [
      openssh
    ];

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
  };
}
