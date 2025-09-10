{
  config,
  ...
}:
{
  services.openssh = {
    enable = true;
    settings = {
      AllowUsers = [
        config.my.user.name
      ];
      ClientAliveCountMax = 2;
      ClientAliveInterval = 300;
      KbdInteractiveAuthentication = false;
      LoginGraceTime = 30;
      MaxAuthTries = 3;
      PasswordAuthentication = false;
      PermitEmptyPasswords = false;
      PermitRootLogin = "no";
      Protocol = 2;
      PubkeyAuthentication = true;
      X11Forwarding = true;
    };
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [ 22 ];
}
