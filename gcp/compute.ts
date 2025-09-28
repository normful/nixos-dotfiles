import * as gcp from "@pulumi/gcp";
import * as pulumi from "@pulumi/pulumi";
import {
  bigMachineType,
  bootDiskSizeGB,
  bootDiskType,
  imageFamily,
  imageProject,
  projectId,
  region,
  smallMachineType,
  sshPublicKey,
  stack,
  zone,
} from "./config";
import { commonLabels } from "./config";
import { network, subnetwork } from "./network";
import { vmTag } from "./firewall";
import { gcpProvider } from "./provider";

export const autoStartStopPolicy = new gcp.compute.ResourcePolicy(
  `${stack}-daily-start-stop-policy`,
  {
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
  },
  { provider: gcpProvider },
);

// e.g. a free Ubuntu image, only for initial use
const recentNonNixosLinuxImage = gcp.compute.getImage(
  {
    project: imageProject,
    family: imageFamily,
    mostRecent: true,
  },
  { provider: gcpProvider },
);

export const bootDisk = new gcp.compute.Disk(
  `${stack}-boot-disk`,
  {
    image: recentNonNixosLinuxImage.then((img) => img.selfLink),
    size: bootDiskSizeGB,
    type: bootDiskType,
    zone: zone,
    labels: commonLabels,
  },
  { protect: true, provider: gcpProvider },
);

// Choose machine type based on whether this is the first NixOS install
// Use more powerful instance for initial builds which are resource-intensive
const selectedMachineType = process.env.USE_BIGGER_INSTANCE
  ? bigMachineType
  : smallMachineType;

export const instance = process.env.INITIAL_PULUMI_PARTIAL_SETUP
  ? undefined
  : new gcp.compute.Instance(
      stack,
      {
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
          scopes: [
            "https://www.googleapis.com/auth/compute",
            "https://www.googleapis.com/auth/logging.write",
            "https://www.googleapis.com/auth/monitoring.write",
          ],
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
      },
      { provider: gcpProvider },
    );

export const instanceName = instance?.name;
export const deployedZone = instance?.zone;

export const sshRootCommand = pulumi.interpolate`CLOUDSDK_PYTHON_SITEPACKAGES=1 gcloud compute ssh root@${instanceName} --zone=${deployedZone} --tunnel-through-iap (use before first NixOS install)`;
export const sshUserCommand = pulumi.interpolate`CLOUDSDK_PYTHON_SITEPACKAGES=1 gcloud compute ssh ${process.env.USER}@${instanceName} --zone=${deployedZone} --tunnel-through-iap --strict-host-key-checking=no (use after first NixOS install)`;
export const consoleUrl = instance?.instanceId.apply(
  (id) =>
    `https://console.cloud.google.com/compute/instancesDetail/zones/${zone}/instances/${id}?project=${projectId}`,
);
