{
  config,
  pkgs-stable,
  ...
}:
let
  gh-wrapped = pkgs-stable.callPackage ../packages/gh-wrapped { inherit config; };
in
{
  environment.systemPackages = [
    gh-wrapped
  ];

  sops.secrets = {
    githubClassicPersonalAccessToken = {
      owner = config.my.user.name;
      group = "users";
    };
  };

  systemd.services.add-ssh-key-to-github = {
    description = "Add SSH public key to GitHub account";
    wantedBy = [ "multi-user.target" ];
    after = [ "generate-user-ssh-keys.service" ];
    requires = [ "generate-user-ssh-keys.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = config.my.user.name;
      Group = "users";
      RemainAfterExit = true;
    };
    script = ''
      SSH_DIR="/home/${config.my.user.name}/.ssh"
      PUBLIC_KEY="$SSH_DIR/id_rsa.pub"

      if [ ! -f "$PUBLIC_KEY" ]; then
        echo "SSH public key not found at $PUBLIC_KEY"
        exit 1
      fi

      if ! gh auth status >/dev/null 2>&1; then
        echo "GitHub CLI gh is not authenticated."
        exit 1
      fi

      KEY_TITLE="${config.my.user.name}@${config.my.hostname}-$(date +%Y%m%d)"

      echo "Adding SSH key to GitHub with title: $KEY_TITLE"
      gh ssh-key add "$PUBLIC_KEY" --title "$KEY_TITLE" --type "authentication"

      if [ $? -eq 0 ]; then
        echo "SSH key successfully added to GitHub"
      else
        echo "Failed to add SSH key to GitHub"
        exit 1
      fi
    '';
  };
}
