import * as gcp from "@pulumi/gcp";
import { stack, iapTcpForwardingRange } from "./config";
import { network } from "./network";
import { gcpProvider } from "./provider";

export const vmTag = `${stack}-vm`;
const lowFirewallRulePriority = 65534;

export const ingressAllowIapSsh = new gcp.compute.Firewall(`${stack}-ingress-allow-iap-ssh`, {
  network: network.id,
  direction: "INGRESS",
  allows: [{ protocol: "tcp", ports: ["22"] }],
  sourceRanges: [iapTcpForwardingRange],
  targetTags: [vmTag],
  description:
    "Allow incoming SSH access via Identity-Aware Proxy TCP forwarding. This enables secure access without public IP addresses by routing through Google's IAP service.",
  logConfig: {
    metadata: "INCLUDE_ALL_METADATA",
  },
}, { provider: gcpProvider });

export const egressAllowTailscaleCoordination = new gcp.compute.Firewall(`${stack}-egress-allow-tailscale-coordination`, {
  network: network.id,
  direction: "EGRESS",
  allows: [
    // https://tailscale.com/kb/1082/firewall-ports
    { protocol: "tcp", ports: ["443", "80"] }, // HTTPS/HTTP for coordination servers
    { protocol: "udp", ports: ["3478"] }, // STUN servers
  ],
  destinationRanges: ["0.0.0.0/0"],
  targetTags: [vmTag],
  description:
    "Allow outbound Tailscale coordination server communication. Required for Tailscale mesh VPN to establish connections and coordinate with control plane.",
  logConfig: {
    metadata: "INCLUDE_ALL_METADATA",
  },
}, { provider: gcpProvider });

export const ingressAllowTailscaleP2p = new gcp.compute.Firewall(`${stack}-ingress-allow-tailscale-p2p`, {
  network: network.id,
  direction: "INGRESS",
  allows: [
    // https://tailscale.com/kb/1082/firewall-ports
    {
      protocol: "udp",
      ports: ["41641"],
    },
  ],
  sourceRanges: ["0.0.0.0/0"],
  targetTags: [vmTag],
  description:
    "Allow Tailscale peer-to-peer communication on default UDP port. Required for direct connections between Tailscale nodes in the mesh network.",
  logConfig: {
    metadata: "EXCLUDE_ALL_METADATA",
  },
}, { provider: gcpProvider });

export const ingressDenyOthers = new gcp.compute.Firewall(`${stack}-ingress-deny-others`, {
  network: network.id,
  direction: "INGRESS",
  denies: [{ protocol: "all" }],
  sourceRanges: ["0.0.0.0/0"],
  targetTags: [vmTag],
  priority: lowFirewallRulePriority,
  description: "Catch-all rule to deny any all other ingress traffic",
  logConfig: {
    metadata: "INCLUDE_ALL_METADATA",
  },
}, { provider: gcpProvider });