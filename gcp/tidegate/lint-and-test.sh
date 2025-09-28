#!/bin/bash

set -euo pipefail

echo "Running golangci-lint..."
golangci-lint run --timeout=5m

echo "Running unit tests..."
go test -v ./...

echo "Linting and testing completed successfully!"