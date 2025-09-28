#!/usr/bin/env bash

set -euo pipefail

# Ensure we return to original directory on exit
trap 'popd' EXIT

IMAGE_NAME="tidegate"
TAG="1.2.1"
PULUMI_STACK="$(pulumi stack --show-name 2>/dev/null)"

# ============================================================================
# Helper Functions
# ============================================================================

error_and_exit() {
  echo "Error: $1" >&2
  exit 1
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

GCP_AR_REPO_REGION="${GCP_AR_REPO_REGION:-$(get_region)}"

# ============================================================================
# Main Script
# ============================================================================

main() {
  pushd "$(dirname "$0")"

  echo "Running golangci-lint..."
  golangci-lint run --timeout=5m

  echo "Building Docker image..."
  docker buildx build --platform linux/amd64 --load --quiet -t "$IMAGE_NAME:$TAG" .

   echo "Configuring Docker authentication..."
   ./docker-auth.sh

  local repository_url
  repository_url=$(get_repository_url)

  local full_image_name="$repository_url/$IMAGE_NAME:$TAG"

  echo "Tagging image as $full_image_name..."
  docker tag "$IMAGE_NAME:$TAG" "$full_image_name"

  echo "Pushing image to $full_image_name..."
  docker push "$full_image_name"

   echo "Successfully built and pushed $full_image_name"
}

main "$@"
