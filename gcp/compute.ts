import * as gcp from "@pulumi/gcp";
import * as pulumi from "@pulumi/pulumi";
import {
  bootDiskSizeGB,
  bootDiskType,
  enableInstanceScheduling,
  enableWeeklySnapshots,
  firstMachineType,
  imageFamily,
  imageProject,
  machineType as machineTypeFromConfig,
  projectId,
  region,
  serviceAccountScopes,
  snapshotRetentionDays,
  sshPublicKey,
  stack,
  zone,
} from "./config";
import { commonLabels } from "./config";
import { network, subnetwork } from "./network";
import { vmTag } from "./firewall";

export const snapshotPolicy = enableWeeklySnapshots
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
export const autoStartStopPolicy = enableInstanceScheduling
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

export const bootDisk = new gcp.compute.Disk(
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

// Choose machine type based on whether this is the first NixOS install
// Use more powerful instance for initial builds which are resource-intensive
const selectedMachineType = process.env.IS_FIRST_NIXOS_INSTALL
  ? firstMachineType
  : machineTypeFromConfig;

export const instance = new gcp.compute.Instance(stack, {
  machineType: selectedMachineType,
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

export const instanceName = instance.name;
export const instanceId = instance.instanceId;
export const bootDiskName = bootDisk.name;
export const machineType = instance.machineType;
export const vmInternalIp = instance.networkInterfaces.apply(
  (ni) => ni[0].networkIp,
);
export const deployedZone = instance.zone;
export const deployedRegion = subnetwork.region;

export const sshRootCommand = pulumi.interpolate`gcloud compute ssh root@${instanceName} --zone=${deployedZone} --tunnel-through-iap (use before first NixOS install)`;
export const sshUserCommand = pulumi.interpolate`gcloud compute ssh ${process.env.USER}@${instanceName} --zone=${deployedZone} --tunnel-through-iap --strict-host-key-checking=no (use after first NixOS install)`;
export const consoleUrl = instance.instanceId.apply(
  (id) =>
    `https://console.cloud.google.com/compute/instancesDetail/zones/${zone}/instances/${id}?project=${projectId}`,
);
