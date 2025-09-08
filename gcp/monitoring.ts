import * as gcp from "@pulumi/gcp";
import { stack, alertEmail, projectId } from "./config";

export const loginMetric = new gcp.logging.Metric(`${stack}-logins-metric`, {
  name: `${stack}_login_events`,
  description: "Count of systemd-logind new session events (user logins)",
  filter: `
    resource.type="gce_instance"
    jsonPayload.SYSLOG_IDENTIFIER="systemd-logind"
    jsonPayload.message=~"New session .* of user .*\\\\\\\\."
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
      {
        key: "leader_pid",
        valueType: "STRING",
        description: "Leader process ID",
      },
    ],
  },
  labelExtractors: {
    user_id: "EXTRACT(jsonPayload.USER_ID)",
    session_id: "EXTRACT(jsonPayload.SESSION_ID)",
    timestamp: "EXTRACT(jsonPayload.timestamp)",
    host: "EXTRACT(jsonPayload.host)",
    leader_pid: "EXTRACT(jsonPayload.LEADER)",
  },
});

export const sshConnectionMetric = new gcp.logging.Metric(
  `${stack}-ssh-conns-metric`,
  {
    name: `${stack}_ssh_connections`,
    description:
      "SSH connection events from Tailscale for correlation with logins",
    filter: `
    resource.type="gce_instance"
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
    name: `${stack}_instance_lifecycle`,
    description:
      "GCP Compute Engine instance start and stop events from Cloud Audit logs",
    filter: `
    (protoPayload.methodName="v1.compute.instances.stop" OR protoPayload.methodName="v1.compute.instances.start")
    logName="projects/${projectId}/logs/cloudaudit.googleapis.com%2Factivity"
    protoPayload.@type="type.googleapis.com/google.cloud.audit.AuditLog"
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
    displayName: "Login Alerts",
    description: "Email notificaton channel",
    type: "email",
    labels: {
      email_address: alertEmail,
    },
  },
  { protect: true },
);

export const loginAlertPolicy = new gcp.monitoring.AlertPolicy(
  `${stack}-login-alert`,
  {
    displayName: `${stack} Login Alert`,
    combiner: "OR",
    conditions: [
      {
        displayName: `VM Instance - ${stack} SSH Connection Events`,
        conditionThreshold: {
          filter: `resource.type = "gce_instance" AND metric.type = "logging.googleapis.com/user/${stack}_ssh_connections"`,
          comparison: "COMPARISON_GT",
          thresholdValue: 0,
          duration: "0s",
          aggregations: [
            {
              alignmentPeriod: "60s",
              perSeriesAligner: "ALIGN_SUM",
            },
          ],
          trigger: {
            count: 1,
          },
        },
      },
    ],
    alertStrategy: {
      autoClose: "1800s",
    },
    notificationChannels: [emailNotificationChannel.name],
    documentation: {
      mimeType: "text/markdown",
      subject: `Login to ${stack} detected`,
      content: `
A login event has been detected in the ${stack} environment.

**Event Details:**
- Source User: {metric.label.source_user_email}
- Source IP: {metric.label.source_ip}
- Target User: {metric.label.target_user}
- Session ID: {metric.label.session_id}
- Host: {metric.label.host}
- Timestamp: {metric.label.timestamp}

This alert is triggered by SSH connection events from Tailscale, which typically indicate user logins to your infrastructure.
      `.trim(),
    },
  },
);

export const instanceLifecycleAlertPolicy = new gcp.monitoring.AlertPolicy(
  `${stack}-instance-lifecycle-alert`,
  {
    displayName: `${stack} Instance Lifecycle Alert`,
    combiner: "OR",
    conditions: [
      {
        displayName: `VM Instance - ${stack} Instance Lifecycle Events`,
        conditionThreshold: {
          filter: `resource.type = "gce_instance" AND metric.type = "logging.googleapis.com/user/${stack}_instance_lifecycle"`,
          comparison: "COMPARISON_GT",
          thresholdValue: 0,
          duration: "0s",
          aggregations: [
            {
              alignmentPeriod: "60s",
              perSeriesAligner: "ALIGN_SUM",
            },
          ],
          trigger: {
            count: 1,
          },
        },
      },
    ],
    alertStrategy: {
      autoClose: "1800s",
    },
    notificationChannels: [emailNotificationChannel.name],
    documentation: {
      mimeType: "text/markdown",
      subject: `${stack} instance lifecycle event detected`,
      content: `
An instance lifecycle event (start or stop) has been detected in the ${stack} environment.

**Event Details:**
- Operation: {metric.label.operation}
- Instance: {metric.label.instance_name} (ID: {metric.label.instance_id})
- Zone: {metric.label.zone}
- User: {metric.label.user_email}
- Operation ID: {metric.label.operation_id}

This alert helps track infrastructure changes and potential security events.
      `.trim(),
    },
  },
);

export const loginMetricName = loginMetric.name;
export const sshConnectionMetricName = sshConnectionMetric.name;
export const instanceLifecycleMetricName = instanceLifecycleMetric.name;
export const emailNotificationChannelName = emailNotificationChannel.name;
export const loginAlertPolicyName = loginAlertPolicy.name;
export const instanceLifecycleAlertPolicyName =
  instanceLifecycleAlertPolicy.name;
