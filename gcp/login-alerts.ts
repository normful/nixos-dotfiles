import * as gcp from "@pulumi/gcp";
import { stack } from "./config";
import { emailNotificationChannel } from "./notification-channels";
import { gcpProvider } from "./provider";

export const sshConnectionMetric = new gcp.logging.Metric(
  `${stack}-ssh-connections-metric`,
  {
    name: `${stack}/ssh_connections`,
    description: "SSH connection events from Tailscale",
    filter: `
    resource.type="gce_instance"
    jsonPayload.host="${stack}"
    jsonPayload.SYSLOG_IDENTIFIER="tailscaled"
    jsonPayload.message=~"ssh-session.*: handling new SSH connection from.*"
  `,
    metricDescriptor: {
      metricKind: "DELTA",
      valueType: "INT64",
      displayName: `${stack} SSH Connection Events`,
      labels: [
        {
          key: "source_user_email",
          valueType: "STRING",
          description: "Tailscale user email initiating SSH connection",
        },
        {
          key: "source_ip",
          valueType: "STRING",
          description: "Source IP address of SSH connection",
        },
        {
          key: "target_user",
          valueType: "STRING",
          description: "Target system user for SSH connection",
        },
        {
          key: "session_id",
          valueType: "STRING",
          description: "Tailscale SSH session identifier",
        },
        {
          key: "timestamp",
          valueType: "STRING",
          description: "SSH connection timestamp",
        },
        {
          key: "host",
          valueType: "STRING",
          description: "Target host name",
        },
      ],
    },
    labelExtractors: {
      source_user_email:
        'REGEXP_EXTRACT(jsonPayload.message, "from ([^\\\\s]+@[^\\\\s]+)")',
      source_ip:
        'REGEXP_EXTRACT(jsonPayload.message, "\\\\(([0-9\\\\.]+)\\\\)")',
      target_user:
        'REGEXP_EXTRACT(jsonPayload.message, "ssh-user \\\\\\"([^\\\\\\"]+)\\\\\\"")',
      session_id:
        'REGEXP_EXTRACT(jsonPayload.message, "ssh-session\\\\(([^\\\\)]+)\\\\)")',
      timestamp: "EXTRACT(jsonPayload.timestamp)",
      host: "EXTRACT(jsonPayload.host)",
    },
  },
  { provider: gcpProvider },
);

export const loginAlertPolicy = new gcp.monitoring.AlertPolicy(
  `${stack}-login-alert`,
  {
    displayName: `${stack} Login Alert`,
    severity: "WARNING",
    combiner: "OR",
    conditions: [
      {
        displayName: `${stack} SSH Connection`,
        conditionThreshold: {
          filter: `resource.type = "gce_instance" AND metric.type = "logging.googleapis.com/user/${stack}/ssh_connections"`,
          aggregations: [
            {
              alignmentPeriod: "60s",
              crossSeriesReducer: "REDUCE_NONE",
              perSeriesAligner: "ALIGN_COUNT",
            },
          ],
          comparison: "COMPARISON_GT",
          thresholdValue: 0,
          duration: "0s",
          trigger: {
            count: 1,
          },
        },
      },
    ],
    alertStrategy: {
      autoClose: "1800s",
      notificationPrompts: ["OPENED"],
    },
    notificationChannels: [emailNotificationChannel.name],
  },
  { provider: gcpProvider },
);
