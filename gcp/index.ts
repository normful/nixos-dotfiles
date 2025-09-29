export { projectId } from "./config";

import "./network";
import "./artifact-registry";
import "./nat-ip-manager-scheduler";
export {
  artifactRegistryRepositoryUrl,
  artifactRegistryServiceAccountKeyValue,
} from "./artifact-registry";

import "./compute";
import "./firewall";
import "./iap-iam";
import "./login-alerts";
import "./instance-start-stop-alerts";
export {
  deployedZone,
  instanceName,
  sshRootCommand,
  sshUserCommand,
} from "./compute";
