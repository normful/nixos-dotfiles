import * as gcp from "@pulumi/gcp";
import { alertEmail } from "./config";
import { gcpProvider } from "./provider";

export const emailNotificationChannel = new gcp.monitoring.NotificationChannel(
  `email-notification-channel`,
  {
    displayName: "Email notification channel",
    type: "email",
    labels: {
      email_address: alertEmail,
    },
  },
  { provider: gcpProvider },
);
