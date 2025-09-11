import * as gcp from "@pulumi/gcp";
import { stack, alertEmail, projectId } from "./config";

export const loginMetric = new gcp.logging.Metric(`${stack}-logins-metric`, {
  name: `${stack}/logins`,
  description: "Count of systemd-logind new session events (user logins)",
  filter: `
    resource.type="gce_instance"
    jsonPayload.host="${stack}"
    jsonPayload.SYSLOG_IDENTIFIER="systemd-logind"
    jsonPayload.message=~"New session .* of user .*"
  `,
  metricDescriptor: {
    metricKind: "DELTA",
    valueType: "INT64",
    displayName: `${stack} Login Events`,
    labels: [
      {
        key: "user_id",
        valueType: "STRING",
        description: "System user ID from systemd-logind",
      },
      {
        key: "session_id",
        valueType: "STRING",
        description: "systemd session identifier",
      },
      {
        key: "timestamp",
        valueType: "STRING",
        description: "Login timestamp",
      },
      {
        key: "host",
        valueType: "STRING",
        description: "Target host name",
      },
    ],
  },
  labelExtractors: {
    user_id: "EXTRACT(jsonPayload.USER_ID)",
    session_id: "EXTRACT(jsonPayload.SESSION_ID)",
    timestamp: "EXTRACT(jsonPayload.timestamp)",
    host: "EXTRACT(jsonPayload.host)",
  },
});

export const sshConnectionMetric = new gcp.logging.Metric(
  `${stack}-ssh-conns-metric`,
  {
    name: `${stack}/ssh_connections`,
    description:
      "SSH connection events from Tailscale for correlation with logins",
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
);

export const instanceLifecycleMetric = new gcp.logging.Metric(
  `${stack}-instance-lifecycle`,
  {
    name: `${stack}/instance_lifecycle`,
    description:
      "GCP Compute Engine instance beginning of start and stop events from Cloud Audit logs",
    filter: `
    (protoPayload.methodName="v1.compute.instances.stop" OR protoPayload.methodName="v1.compute.instances.start")
    logName="projects/${projectId}/logs/cloudaudit.googleapis.com%2Factivity"
    protoPayload.@type="type.googleapis.com/google.cloud.audit.AuditLog"
    operation.first="true"
  `,
    metricDescriptor: {
      metricKind: "DELTA",
      valueType: "INT64",
      displayName: `${stack} Instance Lifecycle Events`,
      labels: [
        {
          key: "operation",
          valueType: "STRING",
          description: "Instance operation: start or stop",
        },
        {
          key: "instance_name",
          valueType: "STRING",
          description: "Name of the GCP instance",
        },
        {
          key: "instance_id",
          valueType: "STRING",
          description: "Unique instance ID",
        },
        {
          key: "zone",
          valueType: "STRING",
          description: "GCP zone where the instance is located",
        },
        {
          key: "user_email",
          valueType: "STRING",
          description: "Email of the user who initiated the operation",
        },
        {
          key: "operation_id",
          valueType: "STRING",
          description: "GCP operation ID for tracking",
        },
      ],
    },
    labelExtractors: {
      operation:
        'REGEXP_EXTRACT(protoPayload.methodName, "v1\\\\.compute\\\\.instances\\\\.(start|stop)")',
      instance_name:
        'REGEXP_EXTRACT(protoPayload.resourceName, "instances/([^/]+)$")',
      instance_id: "EXTRACT(resource.labels.instance_id)",
      zone: "EXTRACT(resource.labels.zone)",
      user_email: "EXTRACT(protoPayload.authenticationInfo.principalEmail)",
      operation_id: "EXTRACT(protoPayload.response.name)",
    },
  },
);

export const emailNotificationChannel = new gcp.monitoring.NotificationChannel(
  `email-notification-channel`,
  {
    displayName: "Email notification channel",
    type: "email",
    labels: {
      email_address: alertEmail,
    },
  },
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
);

export const instanceLifecycleAlertPolicy = new gcp.monitoring.AlertPolicy(
  `${stack}-instance-lifecycle-alert`,
  {
    displayName: `${stack} Instance Lifecycle Alert`,
    severity: "WARNING",
    combiner: "OR",
    conditions: [
      {
        displayName: `${stack} Started/Stopped`,
        conditionThreshold: {
          filter: `resource.type = "gce_instance" AND metric.type = "logging.googleapis.com/user/${stack}/instance_lifecycle"`,
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
);

export const loginMetricName = loginMetric.name;
export const sshConnectionMetricName = sshConnectionMetric.name;
export const instanceLifecycleMetricName = instanceLifecycleMetric.name;
export const emailNotificationChannelName = emailNotificationChannel.name;
export const loginAlertPolicyName = loginAlertPolicy.name;
export const instanceLifecycleAlertPolicyName =
  instanceLifecycleAlertPolicy.name;
