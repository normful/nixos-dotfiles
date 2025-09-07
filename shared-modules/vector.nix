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
      [sources.my_source_id]
      type = "journald"
      batch_size = 16
      current_boot_only = true
      data_dir = "/var/lib/vector"
      extra_args = [ "--merge" ]
      include_units = [ "ntpd" ]

        [sources.my_source_id.exclude_matches]
        _SYSTEMD_UNIT = [ "sshd.service", "ntpd.service" ]
        _TRANSPORT = [ "kernel" ]

        [sources.my_source_id.include_matches]
        _SYSTEMD_UNIT = [ "sshd.service", "ntpd.service" ]
        _TRANSPORT = [ "kernel" ]
    '';
  };
}
/*
  enable = true;
        }
*/
