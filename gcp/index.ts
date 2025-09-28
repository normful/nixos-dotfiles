import "./network";
import "./artifact-registry";
import "./nat-ip-manager-scheduler";
import "./compute";
import "./firewall";
import "./iap-iam";
import "./login-alerts";
import "./instance-start-stop-alerts";

export { projectId } from "./config";
export { deployedZone, instanceName } from "./compute";
export {
  artifactRegistryRepositoryUrl,
  artifactRegistryServiceAccountKeyValue,
} from "./artifact-registry";
