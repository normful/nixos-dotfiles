import * as gcp from "@pulumi/gcp";
import { stack, projectId } from "./config";
import { emailNotificationChannel } from "./notification-channels";
import { gcpProvider } from "./provider";

const instanceLabels = [
  {
    key: "instance_name",
    valueType: "STRING",
    description: "Name of the GCP instance",
  },
  {
    key: "instance_id",
    valueType: "STRING",
    description: "Unique instance ID",
  },
  {
    key: "zone",
    valueType: "STRING",
    description: "GCP zone where the instance is located",
  },
  {
    key: "user_email",
    valueType: "STRING",
    description: "Email of the user who initiated the operation",
  },
  {
    key: "operation_id",
    valueType: "STRING",
    description: "GCP operation ID for tracking",
  },
];

const instanceLabelExtractors = {
  instance_name:
    'REGEXP_EXTRACT(protoPayload.resourceName, "instances/([^/]+)$")',
  instance_id: "EXTRACT(resource.labels.instance_id)",
  zone: "EXTRACT(resource.labels.zone)",
  user_email: "EXTRACT(protoPayload.authenticationInfo.principalEmail)",
  operation_id: "EXTRACT(protoPayload.response.name)",
};

function createInstanceMetric(operation: "start" | "stop") {
  const capOp = operation.charAt(0).toUpperCase() + operation.slice(1);
  return new gcp.logging.Metric(
    `${stack}-instance-${operation}`,
    {
      name: `${stack}/instance_${operation}`,
      description: `GCP Compute Engine instance ${operation} events from Cloud Audit logs`,
      filter: `protoPayload.methodName="v1.compute.instances.${operation}"
      logName="projects/${projectId}/logs/cloudaudit.googleapis.com%2Factivity"
      protoPayload.@type="type.googleapis.com/google.cloud.audit.AuditLog"
      operation.first="true"`,
      metricDescriptor: {
        metricKind: "DELTA",
        valueType: "INT64",
        displayName: `${stack} Instance ${capOp} Events`,
        labels: instanceLabels,
      },
      labelExtractors: instanceLabelExtractors,
    },
    { provider: gcpProvider },
  );
}

function createInstanceAlertPolicy(operation: "start" | "stop") {
  const capOp = operation.charAt(0).toUpperCase() + operation.slice(1);
  return new gcp.monitoring.AlertPolicy(
    `${stack}-instance-${operation}-alert`,
    {
      displayName: `${stack} Instance ${capOp} Alert`,
      severity: "WARNING",
      combiner: "OR",
      conditions: [
        {
          displayName: `Instance ${stack} ${capOp}`,
          conditionThreshold: {
            filter: `resource.type = "gce_instance" AND metric.type = "logging.googleapis.com/user/${stack}/instance_${operation}"`,
            aggregations: [
              {
                alignmentPeriod: "60s",
                crossSeriesReducer: "REDUCE_NONE",
                perSeriesAligner: "ALIGN_COUNT",
              },
            ],
            comparison: "COMPARISON_GT",
            thresholdValue: 0,
            duration: "0s",
            trigger: {
              count: 1,
            },
          },
        },
      ],
      alertStrategy: {
        autoClose: "1800s",
        notificationPrompts: ["OPENED"],
      },
      notificationChannels: [emailNotificationChannel.name],
    },
    { provider: gcpProvider },
  );
}

export const instanceStartMetric = createInstanceMetric("start");
export const instanceStopMetric = createInstanceMetric("stop");
export const instanceStartAlertPolicy = createInstanceAlertPolicy("start");
export const instanceStopAlertPolicy = createInstanceAlertPolicy("stop");
