import { projectId } from "./config";

import "./network";
import "./firewall";
import "./compute";
import "./iam";
import "./monitoring";

export { projectId };
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
export { loggingServiceAccountEmail, loggingServiceAccountKey } from "./iam";
export {
  loginMetricName,
  sshConnectionMetricName,
  emailNotificationChannelName,
  loginAlertPolicyName,
} from "./monitoring";
