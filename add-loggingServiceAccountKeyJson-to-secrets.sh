#!/usr/bin/env bash

set -euo pipefail

if [ -z "${GCP_VM_HOSTNAME:-}" ]; then
    echo "Error: GCP_VM_HOSTNAME environment variable is not set"
    exit 1
fi

SECRETS_FILE="secrets/gcp_$GCP_VM_HOSTNAME.yaml"

if [ ! -f "$SECRETS_FILE" ]; then
    echo "Error: Secrets file $SECRETS_FILE does not exist"
    exit 1
fi

sops set "$SECRETS_FILE" '["loggingServiceAccountKeyJson"]' "$(pulumi stack output loggingServiceAccountKey --show-secrets | base64 -d | jq -c -r .)"

echo "Successfully updated loggingServiceAccountKeyJson in $SECRETS_FILE"
