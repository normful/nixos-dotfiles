#!/usr/bin/env bash

set -euo pipefail

# ============================================================================
# Helper Functions
# ============================================================================

error_and_exit() {
  echo "Error: $1" >&2
  exit 1
}

check_dependencies() {
  local missing_deps=()

  if ! command -v gcloud &> /dev/null; then
    missing_deps+=("gcloud")
  fi

  if ! command -v pulumi &> /dev/null; then
    missing_deps+=("pulumi")
  fi

  if ! command -v docker &> /dev/null; then
    missing_deps+=("docker")
  fi

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    error_and_exit "Missing required dependencies: ${missing_deps[*]}"
  fi
}

get_service_account_key() {
  local key_value

  if ! key_value=$(pulumi stack output artifactRegistryServiceAccountKeyValue --show-secrets 2>/dev/null); then
    error_and_exit "Failed to get service account key from Pulumi stack '$PULUMI_STACK'. Make sure you're in the correct directory and stack is selected."
  fi

  if [[ -z "$key_value" ]]; then
    error_and_exit "Service account key is empty"
  fi

  echo "$key_value"
}

get_repository_url() {
  local repo_url

  if ! repo_url=$(pulumi stack output artifactRegistryRepositoryUrl 2>/dev/null); then
    error_and_exit "Failed to get repository URL from Pulumi stack '$PULUMI_STACK'. Make sure you're in the correct directory and stack is selected."
  fi

  if [[ -z "$repo_url" ]]; then
    error_and_exit "Repository URL is empty"
  fi

  echo "$repo_url"
}

get_region() {
  local repo_url
  repo_url=$(get_repository_url)
  echo "$repo_url" | sed 's/-docker.*//'
}

# ============================================================================
# Configuration
# ============================================================================

PULUMI_STACK="${PULUMI_STACK:-$(pulumi stack --show-name 2>/dev/null || echo "coral")}"
GCP_AR_REPO_REGION="${GCP_AR_REPO_REGION:-$(get_region)}"

configure_docker_auth() {
  local region="$1"
  local service_account_key="$2"

  echo "Configuring Docker authentication for $region-docker.pkg.dev..."

  # Use the service account key directly with docker login
  # The _json_key_base64 username tells Docker to expect a base64-encoded service account key
  if ! echo "$service_account_key" | docker login -u _json_key_base64 --password-stdin "https://${region}-docker.pkg.dev"; then
    error_and_exit "Failed to authenticate with Docker using service account key"
  fi

  echo "Docker authentication configured successfully!"
}

# ============================================================================
# Main Script
# ============================================================================

main() {
  echo "Setting up Docker authentication for GCP Artifact Registry..."
  echo "Region: $GCP_AR_REPO_REGION"
  echo "Stack: $PULUMI_STACK"

  check_dependencies

  local service_account_key
  service_account_key=$(get_service_account_key)

  local repository_url
  repository_url=$(get_repository_url)

  configure_docker_auth "$GCP_AR_REPO_REGION" "$service_account_key"

  echo "You can now push/pull images to/from $repository_url"
  echo ""
  echo "Example usage:"
  echo "  docker tag my-image $repository_url/my-image:tag"
  echo "  docker push $repository_url/my-image:tag"
}

main "$@"
