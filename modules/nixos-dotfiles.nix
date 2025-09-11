{
  config,
  pkgs-stable,
  ...
}:
{
  systemd.services.clone-nixos-dotfiles = {
    description = "Clone nixos-dotfiles repository";
    wantedBy = [ "multi-user.target" ];
    after = [ "add-ssh-key-to-github.service" ];
    requires = [ "add-ssh-key-to-github.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = config.my.user.name;
      Group = "users";
      RemainAfterExit = true;
    };
    path = [ pkgs-stable.git ];
    script = ''
      CODE_DIR="/home/${config.my.user.name}/code"
      REPO_DIR="$CODE_DIR/nixos-dotfiles"

      echo "Ensuring code directory exists: $CODE_DIR"
      mkdir -p "$CODE_DIR"

      if [ -d "$REPO_DIR" ]; then
        echo "Repository already exists at $REPO_DIR"
        exit 0
      fi

      echo "Cloning nixos-dotfiles repository to $REPO_DIR"
      git clone git@github.com:normful/nixos-dotfiles.git "$REPO_DIR"

      if [ $? -eq 0 ]; then
        echo "Repository successfully cloned to $REPO_DIR"
      else
        echo "Failed to clone repository"
        exit 1
      fi
    '';
  };
}