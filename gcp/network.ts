import * as gcp from "@pulumi/gcp";
import { stack, region, subnetCidrRange } from "./config";
import { gcpProvider } from "./provider";

export const network = new gcp.compute.Network(
  `${stack}-vpc`,
  {
    routingMode: "REGIONAL",
    autoCreateSubnetworks: false,
    deleteDefaultRoutesOnCreate: false,
  },
  { provider: gcpProvider },
);

export const subnetwork = new gcp.compute.Subnetwork(
  `${stack}-subnet`,
  {
    network: network.id,
    ipCidrRange: subnetCidrRange,
    region: region,
    privateIpGoogleAccess: true,
  },
  { provider: gcpProvider },
);

// RouterNat, Router, public ip Address are all created and destroyed on an schedule
// using the tidegate Docker image. See ./nat-ip-manager-scheduler.ts
