import * as pulumi from "@pulumi/pulumi";
import * as fs from "fs";

const gcpConfig = new pulumi.Config("gcp");
const config = new pulumi.Config("nixos-gce");

/**
 * Reads the SSH public key from the default location.
 * @returns The trimmed SSH public key.
 * @throws An error if the key file cannot be read.
 */
function getSshPublicKey(): string {
  const sshKeyPath = process.env.SSH_PUBLIC_KEY_PATH;
  if (!sshKeyPath) {
    throw new Error("SSH_PUBLIC_KEY_PATH environment variable is not set");
  }
  try {
    return fs.readFileSync(sshKeyPath, "utf8").trim();
  } catch (e) {
    throw new Error(`Could not read SSH public key from ${sshKeyPath}: ${e}`);
  }
}

/**
 * Gets and validates the boot disk size from the Pulumi config.
 * @returns The boot disk size in GB.
 * @throws An error if the value is invalid or less than 10 GB.
 */
function getValidatedBootDiskSizeGB(): number {
  const bootDiskSizeGBRaw = config.require("bootDiskSizeGB", {
    pattern:
      /^([1-9][0-9]{0,4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-6])$/,
  });
  const bootDiskSizeGBNum = Number(bootDiskSizeGBRaw);

  if (bootDiskSizeGBNum < 10) {
    throw new Error(
      `bootDiskSizeGB must be at least 10 GB, got: ${bootDiskSizeGBNum}`,
    );
  }

  return bootDiskSizeGBNum;
}

export const stack = pulumi.getStack();
export const region = config.require("region", {
  pattern: /^[a-z]+-[a-z]+[0-9]$/,
});

export const zone = gcpConfig.require("zone", {
  pattern: /^[a-z]+-[a-z]+[0-9]-[a-z]$/,
});

export const machineType = config.require("machineType", {
  pattern:
    /^[a-z][0-9]-(micro|small|medium|standard|highmem|highcpu)(-[0-9]+)?$/,
});

export const imageProject = config.require("imageProject", {
  minLength: 1,
  maxLength: 63,
  pattern: /^[a-z][a-z0-9-]*$/,
});

export const imageFamily = config.require("imageFamily", {
  minLength: 1,
  maxLength: 63,
  pattern: /^[a-z][a-z0-9-]*$/,
});

export const bootDiskType = config.require("bootDiskType", {
  allowedValues: ["pd-standard", "pd-ssd", "pd-balanced", "pd-extreme"],
});

export const bootDiskDailyBackupHourUTC = config.require(
  "bootDiskDailyBackupHourUTC",
  {
    pattern: /^([01][0-9]|2[0-3]):[0-5][0-9]$/,
  },
);

export const bootDiskSizeGB = getValidatedBootDiskSizeGB();
export const sshPublicKey = getSshPublicKey();
export const projectId = gcpConfig.require("project");

// Network configuration
export const subnetCidrRange = config.get("subnetCidrRange") || "10.0.1.0/24";

// Service account scopes configuration
export const serviceAccountScopes = config.getObject("serviceAccountScopes") as string[] | undefined || [
  "https://www.googleapis.com/auth/compute",
  "https://www.googleapis.com/auth/logging.write",
  "https://www.googleapis.com/auth/monitoring.write",
];

// Snapshot retention configuration (in days)
export const snapshotRetentionDays = config.getNumber("snapshotRetentionDays") || 2;

// Instance scheduling configuration
export const enableInstanceScheduling = config.getBoolean("enableInstanceScheduling") ?? true;

// Identity-Aware Proxy TCP forwarding IP range configuration
// Default is the well-known GCP IAP range, but can be overridden if GCP updates it
export const iapTcpForwardingRange = config.get("iapTcpForwardingRange") || "35.235.240.0/20";
