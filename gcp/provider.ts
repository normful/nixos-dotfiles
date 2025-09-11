import * as gcp from "@pulumi/gcp";
import { projectId, region, zone, commonLabels } from "./config";

/**
 * GCP Provider with billing project configuration.
 * This provider should be used for all GCP resources to ensure proper billing attribution.
 * 
 * Key configuration options:
 * - project: The GCP project ID for resources
 * - billingProject: The project to bill API calls to (useful for shared VPC scenarios)
 * - region/zone: Default region and zone for resources
 * - defaultLabels: Labels automatically applied to all resources
 * - addPulumiAttributionLabel: Adds Pulumi attribution to resources
 */
export const gcpProvider = new gcp.Provider("gcp-provider", {
  project: projectId,
  billingProject: projectId, // Set billing project to the same as the project
  region: region,
  zone: zone,
  defaultLabels: commonLabels,
  addPulumiAttributionLabel: true,
  
  // You can specify a different billing project here if needed:
  // billingProject: "your-billing-project-id",
  
  // Authentication can be configured via environment variables:
  // - GOOGLE_APPLICATION_CREDENTIALS (path to service account key)
  // - GOOGLE_PROJECT, GOOGLE_REGION, GOOGLE_ZONE
  // - Or use credentials property for explicit service account content
});