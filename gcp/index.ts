export { projectId } from "./config";

import "./network";
import "./artifact-registry";
export {
  artifactRegistryRepositoryUrl,
  artifactRegistryServiceAccountKeyValue,
} from "./artifact-registry";
import "./nat-ip-manager-scheduler";

import "./compute";
export {
  deployedZone,
  instanceName,
  sshRootCommand,
  sshUserCommand,
  consoleUrl,
} from "./compute";
import "./firewall";
import "./iap-iam";
import "./login-alerts";
import "./instance-start-stop-alerts";
