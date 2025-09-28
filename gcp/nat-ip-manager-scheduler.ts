import * as gcp from "@pulumi/gcp";
import * as pulumi from "@pulumi/pulumi";
import { projectId, region, stack } from "./config";
import { gcpProvider } from "./provider";
import { artifactRegistryRepositoryUrl } from "./artifact-registry";

const dockerImage = "tidegate";
const dockerTag = "1.2.1";

export const natIpManagerServiceAccount = new gcp.serviceaccount.Account(
  `${stack}-nat-ip-manager-sa`,
  {
    accountId: `${stack}-nat-ip-manager-sa`,
    displayName: "Service account for nat-ip-manager Cloud Run job",
  },
  { provider: gcpProvider },
);

export const natIpManagerCustomRole = new gcp.projects.IAMCustomRole(
  `${stack}_nat_ip_manager_role`,
  {
    roleId: `${stack}_nat_ip_manager_role`,
    title: "Nat IP Manager Role",
    permissions: [
      "compute.addresses.create",
      "compute.addresses.delete",
      "compute.addresses.list",
      "compute.networks.list",
      "compute.networks.updatePolicy",
      "compute.projects.get",
      "compute.routers.create",
      "compute.routers.delete",
      "compute.routers.list",
      "compute.subnetworks.list",
    ],
    project: projectId,
  },
  { provider: gcpProvider },
);

export const natIpManagerRoleBinding = new gcp.projects.IAMMember(
  `${stack}-nat-ip-manager-role-binding`,
  {
    project: projectId,
    role: natIpManagerCustomRole.name,
    member: natIpManagerServiceAccount.email.apply(
      (email) => `serviceAccount:${email}`,
    ),
  },
  {
    provider: gcpProvider,
    dependsOn: [natIpManagerServiceAccount, natIpManagerCustomRole],
  },
);

export const natIpManagerJob = new gcp.cloudrunv2.Job(
  `${stack}-nat-ip-manager-job`,
  {
    location: region,
    deletionProtection: false,
    template: {
      template: {
        serviceAccount: natIpManagerServiceAccount.email,
        containers: [
          {
            image: pulumi.interpolate`${artifactRegistryRepositoryUrl}/${dockerImage}:${dockerTag}`,
            resources: {
              limits: {
                cpu: "1",
                memory: "512Mi",
              },
            },
            envs: [
              { name: "GOOGLE_CLOUD_PROJECT_ID", value: projectId },
              { name: "GOOGLE_CLOUD_REGION", value: region },
              { name: "PULUMI_STACK_NAME", value: stack },
            ],
          },
        ],
      },
    },
  },
  { provider: gcpProvider },
);

export const natIpManagerSchedulerCustomRole = new gcp.projects.IAMCustomRole(
  `${stack}_nat_ip_manager_scheduler_role`,
  {
    roleId: `${stack}_nat_ip_manager_scheduler_role`,
    title: "Nat IP Manager Scheduler Role",
    permissions: ["run.jobs.run", "run.jobs.runWithOverrides"],
    project: projectId,
  },
  { provider: gcpProvider },
);

export const natIpManagerSchedulerServiceAccount =
  new gcp.serviceaccount.Account(
    `${stack}-scheduler-sa`,
    {
      accountId: `${stack}-scheduler-sa`,
      displayName:
        "Service account for Cloud Scheduler job to invoke Cloud Run v2 Job",
    },
    { provider: gcpProvider },
  );

export const natIpManagerIamPolicy = new gcp.cloudrunv2.JobIamPolicy(
  `${stack}-nat-ip-manager-invoker`,
  {
    location: region,
    project: projectId,
    name: natIpManagerJob.name,
    policyData: natIpManagerSchedulerServiceAccount.email.apply((email) =>
      JSON.stringify({
        bindings: [
          {
            role: `projects/${projectId}/roles/${stack}_nat_ip_manager_scheduler_role`,
            members: [`serviceAccount:${email}`],
          },
        ],
      }),
    ),
  },
  {
    provider: gcpProvider,
    dependsOn: [natIpManagerJob, natIpManagerSchedulerCustomRole],
  },
);

function createNatIpManagerScheduler(operation: string, hour: number) {
  return new gcp.cloudscheduler.Job(
    `${stack}-nat-ip-manager-scheduler-${operation.toLowerCase()}`,
    {
      name: `${stack}-nat-ip-manager-scheduler-${operation.toLowerCase()}`,
      description: `Trigger for nat-ip-manager Cloud Run job at ${hour} AM JST`,
      schedule: `0 ${hour} * * *`,
      timeZone: "Asia/Tokyo",
      httpTarget: {
        uri: natIpManagerJob.name.apply(
          (name) =>
            `https://run.googleapis.com/v2/projects/${projectId}/locations/${region}/jobs/${name}:run`,
        ),
        httpMethod: "POST",
        body: Buffer.from(
          JSON.stringify({
            overrides: {
              containerOverrides: [
                {
                  env: [{ name: "OPERATION", value: operation }],
                },
              ],
            },
          }),
        ).toString("base64"),
        oauthToken: {
          serviceAccountEmail: natIpManagerSchedulerServiceAccount.email,
        },
      },
    },
    { provider: gcpProvider, dependsOn: [natIpManagerIamPolicy] },
  );
}

export const natIpManagerSchedulerCreate = createNatIpManagerScheduler(
  "CREATE",
  20,
);
export const natIpManagerSchedulerDelete = createNatIpManagerScheduler(
  "DELETE",
  23,
);
