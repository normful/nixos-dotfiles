{
  lib,
  ...
}:
{
  networking.firewall.enable = true;

  services.fail2ban = {
    enable = true;
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h";  # 1 week max
      overalljails = true;
    };
    jails = {
      DEFAULT = {
        settings = {
          bantime = lib.mkForce 86400;  # 24 hours
          findtime = lib.mkForce 600;   # 10 minutes
          maxretry = lib.mkForce 2;
        };
      };
      sshd = {
        settings = {
          filter = "sshd";
        };
      };
    };
  };

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = true;
    };
  };
}
