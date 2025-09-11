import { projectId } from "./config";
import "./provider";

import "./network";
import "./firewall";
import "./compute";
import "./iam";
import "./monitoring";

export { projectId };
export { gcpProvider } from "./provider";
export {
  networkName,
  subnetworkName,
  publicNatGatewayName,
  publicNatGatewayIpAddress,
} from "./network";
export {
  instanceName,
  instanceId,
  bootDiskName,
  machineType,
  vmInternalIp,
  deployedZone,
  deployedRegion,
  sshRootCommand,
  sshUserCommand,
  consoleUrl,
} from "./compute";
export {
  loginMetricName,
  sshConnectionMetricName,
  emailNotificationChannelName,
  loginAlertPolicyName,
} from "./monitoring";
