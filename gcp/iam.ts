import * as gcp from "@pulumi/gcp";
import { projectId, stack } from "./config";

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
  { protect: true },
);

export const computeInstanceAdmin = new gcp.projects.IAMBinding(
  `${stack}-compute-instance-admin`,
  {
    project: projectId,
    role: "roles/compute.instanceAdmin.v1",
    members: [`user:${iapUserEmail}`],
  },
  { protect: true },
);

export const loggingServiceAccount = new gcp.serviceaccount.Account(
  `${stack}-log-sa`,
  {
    accountId: `${stack}-log-sa`,
    displayName: `${stack} logging service account`,
    description: `Service account for ${stack} to send logs to Cloud Logging`,
  },
);

export const loggingServiceAccountLogWriter = new gcp.projects.IAMMember(`${stack}-log-writer`, {
  project: projectId,
  role: "roles/logging.logWriter",
  member: loggingServiceAccount.email.apply(
    (email) => `serviceAccount:${email}`,
  ),
});

export const loggingKey = new gcp.serviceaccount.Key(`${stack}-log-key`, {
  serviceAccountId: loggingServiceAccount.name,
  keyAlgorithm: "KEY_ALG_RSA_2048",
  privateKeyType: "TYPE_GOOGLE_CREDENTIALS_FILE",
});

export const loggingServiceAccountEmail = loggingServiceAccount.email;
export const loggingServiceAccountKey = loggingKey.privateKey;