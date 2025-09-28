#!/bin/bash

set -euo pipefail

echo "Building tidegate..."
go build -o tidegate ./cmd

echo "Select operation:"
select OPERATION in CREATE DELETE; do
    if [[ -n "$OPERATION" ]]; then
        break
    else
        echo "Invalid selection. Please choose 1 for CREATE or 2 for DELETE."
    fi
done

echo "Running tidegate..."

GOOGLE_CLOUD_PROJECT_ID=dev-vm-provisioning \
GOOGLE_CLOUD_REGION=us-west1 \
OPERATION=$OPERATION \
PULUMI_STACK_NAME=myth \
./tidegate
