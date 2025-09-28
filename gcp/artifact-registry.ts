import * as gcp from "@pulumi/gcp";
import * as pulumi from "@pulumi/pulumi";
import { stack, region, projectId, commonLabels } from "./config";
import { gcpProvider } from "./provider";

// Enable the Artifact Registry API
const artifactRegistryApi = new gcp.projects.Service(
  `${stack}-artifact-registry-api`,
  {
    service: "artifactregistry.googleapis.com",
    disableOnDestroy: false,
  },
  { provider: gcpProvider },
);

// Create the Artifact Registry Repository
export const artifactRegistryRepository = new gcp.artifactregistry.Repository(
  `${stack}-artifact-registry-docker-repo`,
  {
    location: region,
    repositoryId: `${stack}-docker-repo`,
    description: `Artifact Registry repository for ${stack} stack`,
    format: "DOCKER",
    mode: "STANDARD_REPOSITORY",
    vulnerabilityScanningConfig: {
      enablementConfig: "DISABLED",
    },
    cleanupPolicies: [
      {
        id: "delete-old-versions",
        action: "DELETE",
        condition: {
          olderThan: "3d",
          packageNamePrefixes: [],
        },
      },
    ],
    labels: commonLabels,
  },
  {
    provider: gcpProvider,
    dependsOn: [artifactRegistryApi],
  },
);

// Create a service account for Artifact Registry operations
export const artifactRegistryServiceAccount = new gcp.serviceaccount.Account(
  `${stack}-artifact-registry-sa`,
  {
    accountId: `${stack}-artifact-registry`,
    displayName: `Artifact Registry Service Account for ${stack}`,
    description:
      "Service account for pushing/pulling container images to/from Artifact Registry",
  },
  { provider: gcpProvider },
);

// Grant the service account Artifact Registry Writer role
export const artifactRegistryWriterIam = new gcp.projects.IAMMember(
  `${stack}-artifact-registry-writer`,
  {
    project: projectId,
    role: "roles/artifactregistry.writer",
    member: pulumi.interpolate`serviceAccount:${artifactRegistryServiceAccount.email}`,
  },
  { provider: gcpProvider },
);

export const artifactRegistryServiceAccountKey = new gcp.serviceaccount.Key(
  `${stack}-artifact-registry-key`,
  { serviceAccountId: artifactRegistryServiceAccount.name },
  { provider: gcpProvider },
);

export const artifactRegistryRepositoryUrl =
  artifactRegistryRepository.repositoryId.apply(
    (repoId) => `${region}-docker.pkg.dev/${projectId}/${repoId}`,
  );

export const artifactRegistryServiceAccountKeyValue =
  artifactRegistryServiceAccountKey.privateKey;
