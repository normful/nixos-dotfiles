{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.vector;
in {
  options.services.vector = {
    enable = mkEnableOption "Vector log collection and forwarding";

    gcpProjectId = mkOption {
      type = types.str;
      description = "GCP project ID for log forwarding";
    };

    gcpCredentialsFile = mkOption {
      type = types.path;
      description = "Path to GCP service account credentials JSON file";
    };

    logLevel = mkOption {
      type = types.str;
      default = "info";
      description = "Vector log level";
    };

    resourceType = mkOption {
      type = types.str;
      default = "gce_instance";
      description = "GCP resource type for logs (e.g., gce_instance, k8s_container, etc.)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      vector
    ];

    systemd.services.vector = {
      description = "Vector log collector";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      
      serviceConfig = {
        Type = "simple";
        User = "vector";
        Group = "vector";
        ExecStart = "${pkgs.vector}/bin/vector --config /etc/vector/vector.toml";
        Restart = "always";
        RestartSec = "5s";
        
        # Security settings
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictRealtime = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        
        # Allow reading journal
        SupplementaryGroups = [ "systemd-journal" ];
      };
    };

    users.users.vector = {
      isSystemUser = true;
      group = "vector";
      description = "Vector service user";
    };

    users.groups.vector = {};

    environment.etc."vector/vector.toml" = {
      text = ''
        data_dir = "/var/lib/vector"

        [api]
        enabled = true
        address = "127.0.0.1:8686"

        [log_schema]
        host_key = "host"
        message_key = "message"
        timestamp_key = "timestamp"

        [sources.journald_sshd]
        type = "journald"
        include_units = ["ssh.service", "sshd.service"]
        
        [transforms.parse_sshd]
        type = "remap"
        inputs = ["journald_sshd"]
        source = '''
          .host = get_hostname!()
          .service = "sshd"
          
          # Set severity based on message content
          .severity = if match(.message, r'(?i)(failed|failure|error)') {
            "error"
          } else if match(.message, r'(?i)(accepted|successful)') {
            "info"  
          } else if match(.message, r'(?i)(invalid|warning|disconnect)') {
            "warning"
          } else {
            "info"
          }
          
          # Extract IP addresses from SSH logs
          ip_result = parse_regex(.message, r'from (?P<client_ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})')
          if !is_null(ip_result) {
            .client_ip = ip_result.client_ip
          }
          
          # Extract usernames - handle multiple patterns
          user_result = parse_regex(.message, r'(?:user |for )(?P<username>[a-zA-Z0-9_-]+)')
          if !is_null(user_result) {
            .username = user_result.username
          }
          
          # Extract authentication method if present
          method_result = parse_regex(.message, r'(?P<method>publickey|password|keyboard-interactive)')
          if !is_null(method_result) {
            .auth_method = method_result.method
          }
          
          # Add structured fields for common SSH events
          if match(.message, r'session opened') {
            .event_type = "session_start"
          } else if match(.message, r'session closed') {
            .event_type = "session_end"
          } else if match(.message, r'Accepted') {
            .event_type = "auth_success"
          } else if match(.message, r'Failed') {
            .event_type = "auth_failure"
          }
        '''

        [sinks.gcp_logging]
        type = "gcp_stackdriver_logs"
        inputs = ["parse_sshd"]
        project_id = "${cfg.gcpProjectId}"
        credentials_path = "${cfg.gcpCredentialsFile}"
        log_id = "sshd-logs"
        
        # Required resource field for GCP
        [sinks.gcp_logging.resource]
        type = "${cfg.resourceType}"
        
        # Optional: Configure batching for efficiency
        [sinks.gcp_logging.batch]
        max_events = 100
        timeout_secs = 5
        
        # Configure encoding
        [sinks.gcp_logging.encoding]
        codec = "json"
        timestamp_format = "rfc3339"
      '';
      mode = "0644";
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/vector 0755 vector vector -"
    ];
  };
}