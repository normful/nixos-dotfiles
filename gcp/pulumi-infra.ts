import * as gcp from "@pulumi/gcp";
import * as pulumi from "@pulumi/pulumi";
import {
  bootDiskSizeGB,
  bootDiskType,
  enableInstanceScheduling,
  enableWeeklySnapshots,
  iapTcpForwardingRange,
  imageFamily,
  imageProject,
  machineType as machineTypeFromConfig,
  projectId,
  region,
  serviceAccountScopes,
  snapshotRetentionDays,
  sshPublicKey,
  stack,
  subnetCidrRange,
  zone,
} from "./pulumi-infra-config";

const commonLabels = Object.freeze({
  stack: stack,
  managed_by: "pulumi",
});

const network = new gcp.compute.Network(`${stack}-vpc`, {
  routingMode: "REGIONAL",
  autoCreateSubnetworks: false,
  deleteDefaultRoutesOnCreate: false,
});

const subnetwork = new gcp.compute.Subnetwork(`${stack}-subnet`, {
  network: network.id,
  ipCidrRange: subnetCidrRange,
  region: region,
  privateIpGoogleAccess: true,
  logConfig: {
    flowSampling: 0.2,
    aggregationInterval: "INTERVAL_5_SEC",
    metadata: "INCLUDE_ALL_METADATA",
  },
});

const publicNatIpAddress = new gcp.compute.Address(`${stack}-nat-ip-1`, {
  region: region,
  addressType: "EXTERNAL",
  description: "Static public IP address for Cloud NAT (public NAT)",
  labels: commonLabels,
});

const publicNatGateway = new gcp.compute.RouterNat(`${stack}-nat`, {
  region: region,
  router: new gcp.compute.Router(`${stack}-router`, {
    region: region,
    network: network.id,
  }).name,
  natIpAllocateOption: "MANUAL_ONLY",
  natIps: [publicNatIpAddress.selfLink],
  sourceSubnetworkIpRangesToNat: "LIST_OF_SUBNETWORKS",
  subnetworks: [
    {
      name: subnetwork.id,
      sourceIpRangesToNats: ["ALL_IP_RANGES"],
    },
  ],
  minPortsPerVm: 2048,
  enableEndpointIndependentMapping: true,
  logConfig: {
    enable: true,
    filter: "ALL",
  },
});

const iapUserEmail = process.env.IAP_USER_EMAIL;
if (!iapUserEmail) {
  throw new Error("IAP_USER_EMAIL environment variable must be set");
}

new gcp.projects.IAMBinding(
  `${stack}-iap-tunnel-access`,
  {
    project: projectId,
    role: "roles/iap.tunnelResourceAccessor",
    members: [`user:${iapUserEmail}`],
  },
  { protect: true },
);

new gcp.projects.IAMBinding(
  `${stack}-compute-instance-admin`,
  {
    project: projectId,
    role: "roles/compute.instanceAdmin.v1",
    members: [`user:${iapUserEmail}`],
  },
  { protect: true },
);

const vmTag = `${stack}-vm`;
const lowFirewallRulePriority = 65534;
new gcp.compute.Firewall(`${stack}-ingress-allow-iap-ssh`, {
  network: network.id,
  direction: "INGRESS",
  allows: [{ protocol: "tcp", ports: ["22"] }],
  sourceRanges: [iapTcpForwardingRange],
  targetTags: [vmTag],
  description:
    "Allow incoming SSH access via Identity-Aware Proxy TCP forwarding. This enables secure access without public IP addresses by routing through Google's IAP service.",
  logConfig: {
    metadata: "INCLUDE_ALL_METADATA",
  },
});

new gcp.compute.Firewall(`${stack}-egress-allow-tailscale-coordination`, {
  network: network.id,
  direction: "EGRESS",
  allows: [
    // https://tailscale.com/kb/1082/firewall-ports
    { protocol: "tcp", ports: ["443", "80"] }, // HTTPS/HTTP for coordination servers
    { protocol: "udp", ports: ["3478"] }, // STUN servers
  ],
  destinationRanges: ["0.0.0.0/0"],
  targetTags: [vmTag],
  description:
    "Allow outbound Tailscale coordination server communication. Required for Tailscale mesh VPN to establish connections and coordinate with control plane.",
  logConfig: {
    metadata: "INCLUDE_ALL_METADATA",
  },
});

new gcp.compute.Firewall(`${stack}-ingress-allow-tailscale-p2p`, {
  network: network.id,
  direction: "INGRESS",
  allows: [
    // https://tailscale.com/kb/1082/firewall-ports
    {
      protocol: "udp",
      ports: ["41641"],
    },
  ],
  sourceRanges: ["0.0.0.0/0"],
  targetTags: [vmTag],
  description:
    "Allow Tailscale peer-to-peer communication on default UDP port. Required for direct connections between Tailscale nodes in the mesh network.",
  logConfig: {
    metadata: "EXCLUDE_ALL_METADATA",
  },
});

new gcp.compute.Firewall(`${stack}-ingress-deny-others`, {
  network: network.id,
  direction: "INGRESS",
  denies: [{ protocol: "all" }],
  sourceRanges: ["0.0.0.0/0"],
  targetTags: [vmTag],
  priority: lowFirewallRulePriority,
  description: "Catch-all rule to deny any all other ingress traffic",
  logConfig: {
    metadata: "INCLUDE_ALL_METADATA",
  },
});

const snapshotPolicy = enableWeeklySnapshots
  ? new gcp.compute.ResourcePolicy(
      `${stack}-weekly-boot-disk-snapshot`,
      {
        region: region,
        snapshotSchedulePolicy: {
          schedule: {
            weeklySchedule: {
              dayOfWeeks: [
                {
                  day: "SATURDAY",
                  startTime: "19:00", // UTC
                },
              ],
            },
          },
          retentionPolicy: {
            maxRetentionDays: snapshotRetentionDays,
          },
        },
      },
      { protect: true },
    )
  : undefined;

// https://www.pulumi.com/registry/packages/gcp/api-docs/compute/resourcepolicy/#resource-policy-instance-schedule-policy
const autoStartStopPolicy = enableInstanceScheduling
  ? new gcp.compute.ResourcePolicy(`${stack}-daily-start-stop-instance`, {
      region: region,
      description: "Run instance daily 9-20 JST",
      instanceSchedulePolicy: {
        vmStartSchedule: {
          schedule: "0 9 * * *",
        },
        vmStopSchedule: {
          schedule: "0 20 * * *",
        },
        timeZone: "Asia/Tokyo",
      },
    })
  : undefined;

// e.g. a free Ubuntu image, only for initial use
const recentNonNixosLinuxImage = gcp.compute.getImage({
  project: imageProject,
  family: imageFamily,
  mostRecent: true,
});

const bootDisk = new gcp.compute.Disk(
  `${stack}-boot-disk`,
  {
    image: recentNonNixosLinuxImage.then((img) => img.selfLink),
    size: bootDiskSizeGB,
    type: bootDiskType,
    zone: zone,
    resourcePolicies: snapshotPolicy ? [snapshotPolicy.selfLink] : undefined,
    labels: commonLabels,
  },
  { protect: true },
);

const instance = new gcp.compute.Instance(stack, {
  machineType: machineTypeFromConfig,
  bootDisk: {
    source: bootDisk.selfLink,
    autoDelete: false,
  },
  networkInterfaces: [{ network: network.id, subnetwork: subnetwork.id }],
  tags: [vmTag],
  metadata: {
    "ssh-keys": `root:${sshPublicKey}`,
  },
  serviceAccount: {
    scopes: serviceAccountScopes,
  },
  allowStoppingForUpdate: true,
  deletionProtection: false,
  scheduling: {
    preemptible: true,
    automaticRestart: false,
  },
  shieldedInstanceConfig: {
    enableIntegrityMonitoring: true,
    enableVtpm: true,
    enableSecureBoot: false,
  },
  enableDisplay: true,
  resourcePolicies: autoStartStopPolicy?.selfLink,
  labels: commonLabels,
});

const loggingServiceAccount = new gcp.serviceaccount.Account(
  `${stack}-log-sa`,
  {
    accountId: `${stack}-log-sa`,
    displayName: `${stack} logging service account`,
    description: `Service account for ${stack} to send logs to Cloud Logging`,
  },
);

new gcp.projects.IAMMember(`${stack}-log-writer`, {
  project: projectId,
  role: "roles/logging.logWriter",
  member: loggingServiceAccount.email.apply(
    (email) => `serviceAccount:${email}`,
  ),
});

const loggingKey = new gcp.serviceaccount.Key(`${stack}-log-key`, {
  serviceAccountId: loggingServiceAccount.name,
  keyAlgorithm: "KEY_ALG_RSA_2048",
  privateKeyType: "TYPE_GOOGLE_CREDENTIALS_FILE",
});

export const gcpProjectId = projectId;

export const instanceName = instance.name;
export const instanceId = instance.instanceId;
export const bootDiskName = bootDisk.name;
export const machineType = instance.machineType;
export const vmInternalIp = instance.networkInterfaces.apply(
  (ni) => ni[0].networkIp,
);
export const deployedZone = instance.zone;
export const deployedRegion = subnetwork.region;

export const networkName = network.name;
export const subnetworkName = subnetwork.name;
export const publicNatGatewayName = publicNatGateway.name;
export const publicNatGatewayIpAddress = publicNatIpAddress.address;

export const sshCommand = pulumi.interpolate`gcloud compute ssh ${instanceName} --zone=${deployedZone} --tunnel-through-iap`;
export const consoleUrl = instance.instanceId.apply(
  (id) =>
    `https://console.cloud.google.com/compute/instancesDetail/zones/${zone}/instances/${id}?project=${projectId}`,
);

export const loggingServiceAccountEmail = loggingServiceAccount.email;
export const loggingServiceAccountKey = loggingKey.privateKey;

// Login monitoring and alerting
const loginMetric = new gcp.logging.Metric(`${stack}-login-events`, {
  name: `${stack}_login_events`,
  description: "Count of systemd-logind new session events (user logins)",
  filter: `
    resource.type="gce_instance"
    jsonPayload.SYSLOG_IDENTIFIER="systemd-logind"
    jsonPayload.message=~"New session .* of user .*"
  `,
  labelExtractors: {
    user_id: "EXTRACT(jsonPayload.USER_ID)",
    session_id: "EXTRACT(jsonPayload.SESSION_ID)",
    timestamp: "EXTRACT(jsonPayload.timestamp)",
    host: "EXTRACT(jsonPayload.host)",
    leader_pid: "EXTRACT(jsonPayload.LEADER)",
  },
  metricDescriptor: {
    metricKind: "COUNTER",
    valueType: "INT64",
    displayName: `${stack} Login Events`,
  },
});

// Additional metric to capture SSH connection details for correlation
const sshConnectionMetric = new gcp.logging.Metric(`${stack}-ssh-connections`, {
  name: `${stack}_ssh_connections`,
  description: "SSH connection events from Tailscale for correlation with logins",
  filter: `
    resource.type="gce_instance"
    jsonPayload.SYSLOG_IDENTIFIER="tailscaled"
    jsonPayload.message=~"ssh-session.*: handling new SSH connection from.*"
  `,
  labelExtractors: {
    source_user_email: "REGEXP_EXTRACT(jsonPayload.message, \"from (\\\\S+@\\\\S+)\")",
    source_ip: "REGEXP_EXTRACT(jsonPayload.message, \"\\\\((\\\\d+\\\\.\\\\d+\\\\.\\\\d+\\\\.\\\\d+)\\\\)\")",
    target_user: "REGEXP_EXTRACT(jsonPayload.message, \"ssh-user \\\\\\\"(\\\\w+)\\\\\\\"\")",
    session_id: "REGEXP_EXTRACT(jsonPayload.message, \"ssh-session\\\\((\\\\S+)\\\\)\")",
    timestamp: "EXTRACT(jsonPayload.timestamp)",
    host: "EXTRACT(jsonPayload.host)",
  },
  metricDescriptor: {
    metricKind: "COUNTER",
    valueType: "INT64",
    displayName: `${stack} SSH Connection Events`,
  },
});

const emailNotificationChannel = new gcp.monitoring.NotificationChannel(`${stack}-email-alerts`, {
  displayName: `${stack} Login Alerts`,
  description: "Email notifications for login events",
  type: "email",
  labels: {
    email_address: "normful+f@gmail.com",
  },
});

const loginAlertPolicy = new gcp.monitoring.AlertPolicy(`${stack}-daily-login-digest`, {
  displayName: `${stack} Daily Login Digest`,
  combiner: "OR",
  conditions: [
    {
      displayName: "Daily login summary",
      conditionThreshold: {
        filter: `metric.type="logging.googleapis.com/user/${stack}_login_events" resource.type="gce_instance"`,
        comparison: "COMPARISON_GTE",
        thresholdValue: 1,
        duration: "0s",
        aggregations: [
          {
            alignmentPeriod: "86400s", // 24 hours
            perSeriesAligner: "ALIGN_DELTA",
            crossSeriesReducer: "REDUCE_SUM",
            groupByFields: ["metric.label.user_id", "metric.label.host"],
          },
        ],
        trigger: {
          count: 1,
        },
      },
    },
  ],
  alertStrategy: {
    autoClose: "86400s", // 24 hours - auto-close for daily digest
    notificationRateLimit: {
      period: "86400s", // Limit to once per day
    },
  },
  notificationChannels: [emailNotificationChannel.name],
  documentation: {
    content: `# 🔐 Daily Login Digest - ${stack}

## Summary
Login activity detected on your ${stack} instance in the last 24 hours.

## Details Available
Each login event includes:
- **User**: System user account (extracted from USER_ID)
- **Session**: systemd session identifier 
- **Timestamp**: When the login session was established
- **Host**: Target host (${stack} instance)
- **Method**: SSH via Tailscale (correlated from connection logs)

## Security Information
- All logins are through Tailscale SSH with IAP protection
- Sessions are managed by systemd-logind
- Source IP addresses are captured from Tailscale connection logs
- Login method is determined by correlation with SSH session initiation

## View Full Details
To see detailed login information including source IPs and exact timestamps:
1. Go to [Cloud Logging](https://console.cloud.google.com/logs/query)
2. Use this query for the last 24 hours:
\`\`\`
resource.type="gce_instance"
(
  (jsonPayload.SYSLOG_IDENTIFIER="systemd-logind" AND jsonPayload.message=~"New session .* of user .*")
  OR
  (jsonPayload.SYSLOG_IDENTIFIER="tailscaled" AND jsonPayload.message=~"ssh-session.*: handling new SSH connection from.*")
)
timestamp >= "${new Date(Date.now() - 24*60*60*1000).toISOString()}"
\`\`\`

## Alert Configuration
- **Frequency**: Daily digest (maximum 1 email per 24 hours)
- **Trigger**: Any login activity detected
- **Auto-close**: 24 hours after triggering`,
    mimeType: "text/markdown",
  },
});

export const loginMetricName = loginMetric.name;
export const sshConnectionMetricName = sshConnectionMetric.name;
export const emailNotificationChannelName = emailNotificationChannel.name;
export const loginAlertPolicyName = loginAlertPolicy.name;
