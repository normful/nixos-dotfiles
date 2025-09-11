import * as gcp from "@pulumi/gcp";
import { projectId, region, zone, commonLabels } from "./config";

// This is an Explicit Provider Configuration
//
// Related docs:
// https://www.pulumi.com/docs/iac/concepts/resources/providers/#default-and-explicit-providers
// https://www.pulumi.com/docs/iac/concepts/resources/providers/#explicit-provider-configuration
export const gcpProvider = new gcp.Provider("gcp-provider", {
  region: region,
  zone: zone,
  defaultLabels: commonLabels,
  addPulumiAttributionLabel: true,

  /*
   The following 3 lines of config resolves these kinds of errors:

  gcp:projects:ApiKey (coral-logging-api-key):
    error:   sdk-v2/provider2.go:572: sdk.helper_schema: Error creating Key: failed to create a diff: failed to retrieve Key resource: googleapi: Error 403: Your application is authenticating by using local Application Default Credentials. The apikeys.googleapis.com API requires a quota project, which is not set by default. To learn how to set your quota project, see https://cloud.google.com/docs/authentication/adc-troubleshooting/user-creds .
    Details:
    [
      {
        "@type": "type.googleapis.com/google.rpc.ErrorInfo",
        "domain": "googleapis.com",
        "metadata": {
          "consumer": "projects/764086051850",
          "service": "apikeys.googleapis.com"
        },
        "reason": "SERVICE_DISABLED"
      },
      {
        "@type": "type.googleapis.com/google.rpc.LocalizedMessage",
        "locale": "en-US",
        "message": "Your application is authenticating by using local Application Default Credentials. The apikeys.googleapis.com API requires a quota project, which is not set by default. To learn how to set your quota project, see https://cloud.google.com/docs/authentication/adc-troubleshooting/user-creds ."
      }
    ]: provider=google-beta@8.41.1

  based on answer at https://stackoverflow.com/a/79051624
*/
  project: projectId,
  billingProject: projectId,
  userProjectOverride: true,
});
