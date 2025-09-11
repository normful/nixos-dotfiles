#!/usr/bin/env bash
# Installs NixOS on a virtual machine running on Google Compute Engine that was created with Pulumi.

set -o errexit
set -o nounset
set -o pipefail

REPO_DIR="$(git rev-parse --show-toplevel)"

error_and_exit() {
  echo "Error: $1" >&2
  exit 1
}

# ============================================================================
# Environment validation functions
# ============================================================================

ensure_nix_installed() {
  if ! command -v nix &> /dev/null; then
    error_and_exit "Nix is not installed. Please install Nix first."
  fi
}

check_required_env_vars() {
  if [[ -z "${GCP_PROJECT_ID:-}" ]]; then
    error_and_exit "GCP_PROJECT_ID environment variable is not set or is empty"
  fi

  if [[ -z "${GCP_VM_HOSTNAME:-}" ]]; then
    error_and_exit "GCP_VM_HOSTNAME environment variable is not set or is empty"
  fi

  if [[ -z "${GCP_VM_USERNAME:-}" ]]; then
    error_and_exit "GCP_VM_USERNAME environment variable is not set or is empty"
  fi

  if [[ -z "${SSH_PUBLIC_KEY_PATH:-}" ]]; then
    error_and_exit "SSH_PUBLIC_KEY_PATH environment variable is not set"
  fi

  if [[ ! -r "${SSH_PUBLIC_KEY_PATH}" ]]; then
    error_and_exit "SSH public key file at ${SSH_PUBLIC_KEY_PATH} is not readable or does not exist"
  fi

  if [[ -z "${GCE_PRIVATE_KEY_PATH:-}" ]]; then
    error_and_exit "GCE_PRIVATE_KEY_PATH environment variable is not set"
  fi

  if [[ ! -r "${GCE_PRIVATE_KEY_PATH}" ]]; then
    error_and_exit "'gcloud compute ssh' private key file at ${GCE_PRIVATE_KEY_PATH} is not readable or does not exist"
  fi
}

check_secrets_files() {
  local example_secrets="$REPO_DIR/secrets/gcp_example.yaml"
  local hostname_secrets="$REPO_DIR/secrets/gcp_${GCP_VM_HOSTNAME}.yaml"

  if [[ ! -f "$example_secrets" ]]; then
    error_and_exit "Example secrets file at $example_secrets does not exist"
  fi

  if [[ ! -f "$hostname_secrets" ]]; then
    error_and_exit "Hostname-specific secrets file at $hostname_secrets does not exist"
  fi

  local example_checksum=$(sha512sum "$example_secrets" | cut -d' ' -f1)
  local hostname_checksum=$(sha512sum "$hostname_secrets" | cut -d' ' -f1)

  if [[ "$example_checksum" == "$hostname_checksum" ]]; then
    error_and_exit "secrets/gcp_${GCP_VM_HOSTNAME}.yaml is identical to secrets/gcp_example.yaml\nPlease run 'mise run secrets' and add host-specific secrets before deployment."
  fi
}

validate_not_empty() {
  local value="$1"
  local error_message="$2"

  if [[ -z "$value" ]]; then
    error_and_exit "$error_message"
  fi
}

# ============================================================================
# File editing helper functions
# ============================================================================

write_machine_specific_config_into_placeholders() {
  local target="$REPO_DIR/gcp/${GCP_VM_HOSTNAME}/my-config.nix"
  # Use portable sed that works on both Linux and macOS
  sed -i.bak "s|GCP_PROJECT_ID_PLACEHOLDER|${GCP_PROJECT_ID}|g" "$target" && rm -f "$target.bak"
  sed -i.bak "s|GCP_VM_HOSTNAME_PLACEHOLDER|${GCP_VM_HOSTNAME}|g" "$target" && rm -f "$target.bak"
  sed -i.bak "s|GCP_VM_USERNAME_PLACEHOLDER|${GCP_VM_USERNAME}|g" "$target" && rm -f "$target.bak"
  sed -i.bak "s|SSH_PUBLIC_KEY_PLACEHOLDER|$(cat "$SSH_PUBLIC_KEY_PATH")|g" "$target" && rm -f "$target.bak"
}

# ============================================================================
# Utility functions
# ============================================================================

cleanup_tmp_dir() {
  local tmp_dir="$1"
  if [[ -n "$tmp_dir" && -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi
}

copy() {
  cp --archive --link "$1" "$2"
}

# ============================================================================
# Age key management functions
# ============================================================================

validate_age_key() {
  local age_private_key="$1"

  if [[ -z "$age_private_key" ]]; then
    error_and_exit "No age private key provided"
  fi

  if [[ ! "$age_private_key" =~ ^AGE-SECRET-KEY- ]]; then
    error_and_exit "Invalid age private key format (should start with 'AGE-SECRET-KEY-')"
  fi
}

prepare_age_key_file() {
  local tree_to_copy="$1"
  local age_private_key="$2"

  local age_key_dir="$tree_to_copy/root/.config/sops/age"
  mkdir -p "$age_key_dir"
  echo "$age_private_key" > "$age_key_dir/keys.txt"
  chmod 600 "$age_key_dir/keys.txt"
}

# ============================================================================
# File preparation functions
# ============================================================================

copy_nixos_config() {
  local dst="$1"
  mkdir -p "$dst"

  copy "$REPO_DIR/flake.nix" "$dst"
  copy "$REPO_DIR/flake.lock" "$dst"
  copy "$REPO_DIR/gcp/" "$dst"
  copy "$REPO_DIR/secrets/" "$dst"
  copy "$REPO_DIR/modules/" "$dst"
  copy "$REPO_DIR/.sops.yaml" "$dst"
}

# ============================================================================
# NixOS installation functions
# ============================================================================

# Runs nixos-anywhere and connects to the VM instance through its internal IP address,
# using Identity-Aware Proxy (IAP) TCP forwarding.
run_nixos_anywhere() {
  local tree_to_copy="$1"

  local project=$(mise exec pulumi -- pulumi stack output projectId)
  validate_not_empty "$project" "Failed to get projectId from Pulumi stack output"

  local zone=$(mise exec pulumi -- pulumi stack output deployedZone)
  validate_not_empty "$zone" "Failed to get deployedZone from Pulumi stack output"

  local instance_name=$(mise exec pulumi -- pulumi stack output instanceName)
  validate_not_empty "$instance_name" "Failed to get instanceName from Pulumi stack output"

  local instance_id=$(mise exec gcloud -- gcloud compute instances describe "$instance_name" --project="$project" --zone="$zone" --format="value(id)")
  validate_not_empty "$instance_id" "Failed to get instance ID from gcloud"

  export CLOUDSDK_PYTHON_SITEPACKAGES=1

  # Create a simple wrapper script for the ProxyCommand
  local proxy_script=$(mktemp)
  local gcloud_path=$(mise which gcloud)
  validate_not_empty "$gcloud_path" "Failed to get gcloud path"

  # Write a simple proxy script
  cat > "$proxy_script" << EOF
#!/bin/sh
exec "$gcloud_path" compute start-iap-tunnel "$instance_name" 22 --listen-on-stdin --project="$project" --zone="$zone" --verbosity=warning --iap-tunnel-disable-connection-check
EOF
  chmod +x "$proxy_script"

  # Delete temporary script on exit
  trap "rm -f '$proxy_script'" EXIT

  echo "Running nixos-anywhere. If you have a passphrase on $GCE_PRIVATE_KEY_PATH, you will need to enter it shortly (you will be asked for the passphrase to a /tmp copy of your key)..."

  nix run github:nix-community/nixos-anywhere -- \
    --flake ".#$GCP_VM_HOSTNAME-first-install" \
    --target-host "root@compute.$instance_id" \
    --build-on 'remote' \
    --ssh-option "ProxyCommand=$proxy_script" \
    --ssh-option "HostKeyAlias=compute.$instance_id" \
    --ssh-option "CheckHostIP=no" \
    --ssh-option "HashKnownHosts=no" \
    --ssh-option "ProxyUseFdpass=no" \
    --ssh-option "StrictHostKeyChecking=accept-new" \
    -i "$GCE_PRIVATE_KEY_PATH" \
    --extra-files "$tree_to_copy" \
    --debug \
    --show-trace
}

nixos_install() {
  local tree_to_copy=$(mktemp -d)

  trap "cleanup_tmp_dir \"$tree_to_copy\"" EXIT ERR INT TERM

  printf "Please enter the 'age' private key that was used to encrypt secrets/gcp_$GCP_VM_HOSTNAME.yaml:\n"
  printf "The key should start with 'AGE-SECRET-KEY-' and be on a single line.\n"
  printf "'age' private key: "
  read -r -s age_private_key
  echo

  validate_age_key "$age_private_key"
  prepare_age_key_file "$tree_to_copy" "$age_private_key"
  copy_nixos_config "$tree_to_copy/etc/nixos"

  run_nixos_anywhere "$tree_to_copy"
}

# ============================================================================
# Main execution function
# ============================================================================

main() {
  ensure_nix_installed
  check_required_env_vars
  check_secrets_files

  mise exec pulumi -- pulumi stack select "$GCP_VM_HOSTNAME"
  write_machine_specific_config_into_placeholders

  nixos_install
}

main "$@"
