import * as gcp from "@pulumi/gcp";
import * as pulumi from "@pulumi/pulumi";
import {
  bootDiskDailyBackupHourUTC,
  bootDiskSizeGB,
  bootDiskType,
  enableInstanceScheduling,
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

const snapshotPolicy = new gcp.compute.ResourcePolicy(
  `${stack}-daily-boot-disk-snapshot`,
  {
    region: region,
    snapshotSchedulePolicy: {
      schedule: {
        dailySchedule: {
          daysInCycle: 1,
          startTime: bootDiskDailyBackupHourUTC,
        },
      },
      retentionPolicy: {
        maxRetentionDays: snapshotRetentionDays,
      },
    },
  },
  { protect: true },
);

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
    resourcePolicies: [snapshotPolicy.selfLink],
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
    preemptible: false,
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

export const gcpProjectId = projectId;
export const instanceName = instance.name;
export const instanceId = instance.instanceId;
export const vmInternalIp = instance.networkInterfaces.apply(
  (ni) => ni[0].networkIp,
);
export const deployedZone = instance.zone;
export const deployedRegion = subnetwork.region;
export const machineType = instance.machineType;
export const networkName = network.name;
export const subnetworkName = subnetwork.name;
export const bootDiskName = bootDisk.name;
export const sshCommand = pulumi.interpolate`gcloud compute ssh ${instanceName} --zone=${deployedZone} --tunnel-through-iap`;
export const consoleUrl = instance.instanceId.apply(
  (id) =>
    `https://console.cloud.google.com/compute/instancesDetail/zones/${zone}/instances/${id}?project=${projectId}`,
);

export const publicNatGatewayName = publicNatGateway.name;
export const publicNatGatewayIpAddress = publicNatIpAddress.address;
