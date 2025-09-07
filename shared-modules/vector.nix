{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.vector = {
    enable = true;
    journaldAccess = true;
    validateConfig = true;
    settings = ''
      data_dir = "/var/lib/vector"

      [sources.tailscale_logins]
      type = "journald"
      current_boot_only = false
      units = ["tailscaled.service", "systemd-logind.service"]

      [sinks.console]
      type = "console"
      inputs = ["tailscale_logins"]
      encoding.codec = "json"
    '';
  };
}
