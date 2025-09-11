import * as gcp from "@pulumi/gcp";
import { stack, region, subnetCidrRange } from "./config";
import { commonLabels } from "./config";
import { gcpProvider } from "./provider";

export const network = new gcp.compute.Network(`${stack}-vpc`, {
  routingMode: "REGIONAL",
  autoCreateSubnetworks: false,
  deleteDefaultRoutesOnCreate: false,
});

export const subnetwork = new gcp.compute.Subnetwork(`${stack}-subnet`, {
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

export const publicNatIpAddress = new gcp.compute.Address(`${stack}-nat-ip-1`, {
  region: region,
  addressType: "EXTERNAL",
  description: "Static public IP address for Cloud NAT (public NAT)",
  labels: commonLabels,
});

const router = new gcp.compute.Router(`${stack}-router`, {
  region: region,
  network: network.id,
});

export const publicNatGateway = new gcp.compute.RouterNat(`${stack}-nat`, {
  region: region,
  router: router.name,
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

export const networkName = network.name;
export const subnetworkName = subnetwork.name;
export const publicNatGatewayName = publicNatGateway.name;
export const publicNatGatewayIpAddress = publicNatIpAddress.address;
