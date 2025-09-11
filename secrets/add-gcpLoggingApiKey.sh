#!/usr/bin/env bash

set -euo pipefail

# Change to git root directory
cd "$(git rev-parse --show-toplevel)"

if [ -z "${GCP_VM_HOSTNAME:-}" ]; then
    echo "Error: GCP_VM_HOSTNAME environment variable is not set"
    exit 1
fi

SECRETS_FILE="secrets/gcp_$GCP_VM_HOSTNAME.yaml"

if [ ! -f "$SECRETS_FILE" ]; then
    echo "Error: Secrets file $SECRETS_FILE does not exist"
    exit 1
fi

sops set "$SECRETS_FILE" '["gcpLoggingApiKey"]' "\"$(pulumi stack output loggingApiKeyValue --show-secrets)\""

echo "Successfully updated gcpLoggingApiKey in $SECRETS_FILE"
