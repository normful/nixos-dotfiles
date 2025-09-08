{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    my.gcpProjectId = lib.mkOption {
      type = lib.types.str;
      description = "The ID of the Google Cloud Platform Project this instance is in.";
    };
  };

  config = {
    systemd.services.vector = {
      serviceConfig = {
        ExecStartPre = pkgs.writeShellScript "fetch-gcp-metadata" ''
          {
            echo "GCP_PROJECT_ID=$(${pkgs.curl}/bin/curl -s 'http://metadata.google.internal/computeMetadata/v1/project/project-id' -H 'Metadata-Flavor: Google' || echo 'unknown')"
            echo "GCP_INSTANCE_ID=$(${pkgs.curl}/bin/curl -s 'http://metadata.google.internal/computeMetadata/v1/instance/id' -H 'Metadata-Flavor: Google' || echo 'unknown')"
            echo "GCP_ZONE=$(${pkgs.curl}/bin/curl -s 'http://metadata.google.internal/computeMetadata/v1/instance/zone' -H 'Metadata-Flavor: Google' | cut -d/ -f4 || echo 'unknown')"
          } > /run/vector/gcp-env
        '';
        EnvironmentFile = "-/run/vector/gcp-env";
        RuntimeDirectory = "vector";
        RuntimeDirectoryMode = "0755";
      };
    };

    services.vector = {
      enable = true;
      journaldAccess = true;
      settings = {
        data_dir = "/var/lib/vector";

        sources.logins = {
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

        transforms.logins_trimmed = {
          type = "remap";
          inputs = [ "logins" ];
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

            # Delete other unnecessary fields
            del(."_GID")
            del(."_UID")
          '';
        };

        transforms.logins_with_gcp_metadata = {
          type = "remap";
          inputs = [ "logins_trimmed" ];
          source = ''
            .instance = "''${GCP_INSTANCE_ID:-unknown}"
          '';
        };

        sinks = {
          /*
            Uncomment for debugging
            console = {
              type = "console";
              inputs = [ "logins_with_gcp_metadata" ];
              encoding.codec = "json";
            };
          */

          gcp_logs = {
            type = "gcp_stackdriver_logs";
            inputs = [ "logins_with_gcp_metadata" ];
            resource = {
              type = "gce_instance";
            };
            project_id = config.my.gcpProjectId;
            log_id = "${config.my.hostname}-login";
            tls = {
              verify_certificate = true;
            };
            request = {
              retry_attempts = 3;
            };
          };
        };
      };
    };
  };
}
