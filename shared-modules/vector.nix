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
    settings = {
      data_dir = "/var/lib/vector";

      sources.tailscale_logins = {
        type = "journald";
        current_boot_only = true;
        include_units = [
          "tailscaled.service"
          "systemd-logind.service"
        ];
        include_matches = {
          "_COMM" = [ "login" ];
        };
      };

      transforms.remove_fields = {
        type = "remap";
        inputs = [ "tailscale_logins" ];
        source = ''
          # Delete debug/development fields
          del(."CODE_FILE")
          del(."CODE_FUNC")
          del(."CODE_LINE")
          del(."MESSAGE_ID")

          # Delete systemd internal metadata (not security relevant)
          del(."_BOOT_ID")
          del(."_MACHINE_ID")
          del(."_RUNTIME_SCOPE")
          del(."_SYSTEMD_CGROUP")
          del(."_SYSTEMD_INVOCATION_ID")
          del(."_SYSTEMD_SLICE")
          del(."_SYSTEMD_UNIT")
          del(."_SYSTEMD_OWNER_UID")
          del(."_SYSTEMD_USER_SLICE")
          del(."_STREAM_ID")

          # Delete duplicate/redundant timestamp fields
          del(."_SOURCE_REALTIME_TIMESTAMP")
          del(."__MONOTONIC_TIMESTAMP")
          del(."__REALTIME_TIMESTAMP")
          del(."SYSLOG_TIMESTAMP")

          # Delete sequence/ordering fields (not security relevant)
          del(."__SEQNUM")
          del(."__SEQNUM_ID")

          # Delete process metadata (keep _CMDLINE for security context)
          del(."_PID")
          del(."TID")
          del(."SYSLOG_PID")
          del(."_COMM")
          del(."_EXE")

          # Delete transport/facility metadata
          del(."_TRANSPORT")
          del(."PRIORITY")
          del(."SYSLOG_FACILITY")

          # Delete capabilities field (complex, not directly login-relevant)
          del(."_CAP_EFFECTIVE")

          # Delete SELinux context (usually just "kernel", not login-specific)
          del(."_SELINUX_CONTEXT")
        '';
      };

      sinks.console = {
        type = "console";
        inputs = [ "remove_fields" ];
        encoding.codec = "json";
      };
    };
  };
}
