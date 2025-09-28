import * as gcp from "@pulumi/gcp";
import { projectId, stack } from "./config";
import { gcpProvider } from "./provider";

const iapUserEmail = process.env.IAP_USER_EMAIL;
if (!iapUserEmail) {
  throw new Error("IAP_USER_EMAIL environment variable must be set");
}

export const iapTunnelAccess = new gcp.projects.IAMBinding(
  `${stack}-iap-tunnel-access`,
  {
    project: projectId,
    role: "roles/iap.tunnelResourceAccessor",
    members: [`user:${iapUserEmail}`],
  },
  { provider: gcpProvider },
);

export const computeInstanceAdmin = new gcp.projects.IAMBinding(
  `${stack}-compute-instance-admin`,
  {
    project: projectId,
    role: "roles/compute.instanceAdmin.v1",
    members: [`user:${iapUserEmail}`],
  },
  { provider: gcpProvider },
);
