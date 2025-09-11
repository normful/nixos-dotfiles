#!/usr/bin/env bash

REPO_DIR="$(git rev-parse --show-toplevel)"
TESTED_BASH_FILE="$REPO_DIR/gcp/install-nixos.sh"

set -o errexit
set -o pipefail

# Create a temporary modified version of the script without the main execution
TEMP_SCRIPT=$(mktemp)

# Test setup variables
TEST_TMP_DIR=""
TEST_ORIGINAL_ENV=""

# ============================================================================
# Test Setup and Teardown
# ============================================================================

function set_up_before_script() {
    TEST_TMP_DIR=$(mktemp -d)
    # Save original environment variables
    TEST_ORIGINAL_ENV=$(env | grep -E '^(GCP_VM_HOSTNAME|GCP_VM_USERNAME|SSH_PUBLIC_KEY_PATH|GCE_PRIVATE_KEY_PATH)=' || true)

    # Regenerate temp script to pick up any changes to the source
    if [[ -n "$TEMP_SCRIPT" && -f "$TEMP_SCRIPT" ]]; then
        rm -f "$TEMP_SCRIPT"
    fi

    TEMP_SCRIPT=$(mktemp)
    head -n -1 "$TESTED_BASH_FILE" > "$TEMP_SCRIPT"

    # Source the functions from the modified script
    source "$TEMP_SCRIPT"
}

function tear_down_after_script() {
    if [[ -n "$TEST_TMP_DIR" && -d "$TEST_TMP_DIR" ]]; then
        rm -rf "$TEST_TMP_DIR"
    fi

    # Clean up the temporary script
    if [[ -n "$TEMP_SCRIPT" && -f "$TEMP_SCRIPT" ]]; then
        rm -f "$TEMP_SCRIPT"
    fi

    # Restore original environment variables
    unset GCP_VM_HOSTNAME GCP_VM_USERNAME SSH_PUBLIC_KEY_PATH GCE_PRIVATE_KEY_PATH 2>/dev/null || true
    if [[ -n "$TEST_ORIGINAL_ENV" ]]; then
        eval "$TEST_ORIGINAL_ENV"
    fi
}

function set_up() {
    # Reset environment variables for each test
    unset GCP_VM_HOSTNAME GCP_VM_USERNAME SSH_PUBLIC_KEY_PATH GCE_PRIVATE_KEY_PATH 2>/dev/null || true
}

# ============================================================================
# Environment Validation Function Tests
# ============================================================================

function test_ensure_nix_installed_when_nix_exists() {
    command() {
        if [[ "$1" == "-v" && "$2" == "nix" ]]; then
            return 0
        fi
        /usr/bin/command "$@"
    }

    ensure_nix_installed
    assert_true $?
}

function test_ensure_nix_installed_when_nix_missing() {
    mock error_and_exit <<< '$1'

    command() {
        if [[ "$1" == "-v" && "$2" == "nix" ]]; then
            return 1
        fi
        /usr/bin/command "$@"
    }

    assert_same "Nix is not installed. Please install Nix first." "$(ensure_nix_installed)"
}

function test_check_required_env_vars_missing_project_id() {
    mock error_and_exit <<< '$1'

    unset GCP_PROJECT_ID
    export GCP_VM_HOSTNAME="test-host"
    export GCP_VM_USERNAME="testuser"
    export SSH_PUBLIC_KEY_PATH="$TEST_TMP_DIR/test_key.pub"
    export GCE_PRIVATE_KEY_PATH="$TEST_TMP_DIR/test_key"

    echo "ssh-ed25519 ABC test" > "$SSH_PUBLIC_KEY_PATH"
    echo "-----BEGIN OPENSSH PRIVATE KEY-----" > "$GCE_PRIVATE_KEY_PATH"
    chmod 600 "$GCE_PRIVATE_KEY_PATH"

    assert_same "GCP_PROJECT_ID environment variable is not set or is empty" "$(set +u; check_required_env_vars | head -1)"
}

function test_check_required_env_vars_empty_project_id() {
    mock error_and_exit <<< '$1'

    export GCP_PROJECT_ID=""
    export GCP_VM_HOSTNAME="test-host"
    export GCP_VM_USERNAME="testuser"
    export SSH_PUBLIC_KEY_PATH="$TEST_TMP_DIR/test_key.pub"
    export GCE_PRIVATE_KEY_PATH="$TEST_TMP_DIR/test_key"

    echo "ssh-ed25519 ABC test" > "$SSH_PUBLIC_KEY_PATH"
    echo "-----BEGIN OPENSSH PRIVATE KEY-----" > "$GCE_PRIVATE_KEY_PATH"
    chmod 600 "$GCE_PRIVATE_KEY_PATH"

    assert_same "GCP_PROJECT_ID environment variable is not set or is empty" "$(check_required_env_vars | head -1)"
}

function test_check_required_env_vars_all_set() {
    export GCP_PROJECT_ID="test-project"
    export GCP_VM_HOSTNAME="test-host"
    export GCP_VM_USERNAME="testuser"
    export SSH_PUBLIC_KEY_PATH="$TEST_TMP_DIR/test_key.pub"
    export GCE_PRIVATE_KEY_PATH="$TEST_TMP_DIR/test_key"

    echo "ssh-ed25519 ABC test" > "$SSH_PUBLIC_KEY_PATH"
    echo "-----BEGIN OPENSSH PRIVATE KEY-----" > "$GCE_PRIVATE_KEY_PATH"
    chmod 600 "$GCE_PRIVATE_KEY_PATH"

    check_required_env_vars
    assert_true $?
}

function test_check_required_env_vars_missing_hostname() {
    mock error_and_exit <<< '$1'

    export GCP_VM_USERNAME="testuser"
    export SSH_PUBLIC_KEY_PATH="$TEST_TMP_DIR/test_key.pub"
    export GCE_PRIVATE_KEY_PATH="$TEST_TMP_DIR/test_key"

    echo "ssh-ed25519 ABC test" > "$SSH_PUBLIC_KEY_PATH"
    echo "-----BEGIN OPENSSH PRIVATE KEY-----" > "$GCE_PRIVATE_KEY_PATH"
    chmod 600 "$GCE_PRIVATE_KEY_PATH"

    assert_same "GCP_VM_HOSTNAME environment variable is not set or is empty" "$(check_required_env_vars)"
}

function test_check_required_env_vars_empty_hostname() {
    mock error_and_exit <<< '$1'

    export GCP_VM_HOSTNAME=""
    export GCP_VM_USERNAME="testuser"
    export SSH_PUBLIC_KEY_PATH="$TEST_TMP_DIR/test_key.pub"
    export GCE_PRIVATE_KEY_PATH="$TEST_TMP_DIR/test_key"

    echo "ssh-ed25519 ABC test" > "$SSH_PUBLIC_KEY_PATH"
    echo "-----BEGIN OPENSSH PRIVATE KEY-----" > "$GCE_PRIVATE_KEY_PATH"
    chmod 600 "$GCE_PRIVATE_KEY_PATH"

    assert_same "GCP_VM_HOSTNAME environment variable is not set or is empty" "$(check_required_env_vars)"
}

function test_check_required_env_vars_missing_username() {
    mock error_and_exit <<< '$1'

    export GCP_VM_HOSTNAME="test-host"
    export SSH_PUBLIC_KEY_PATH="$TEST_TMP_DIR/test_key.pub"
    export GCE_PRIVATE_KEY_PATH="$TEST_TMP_DIR/test_key"

    echo "ssh-ed25519 ABC test" > "$SSH_PUBLIC_KEY_PATH"
    echo "-----BEGIN OPENSSH PRIVATE KEY-----" > "$GCE_PRIVATE_KEY_PATH"
    chmod 600 "$GCE_PRIVATE_KEY_PATH"

    assert_same "GCP_VM_USERNAME environment variable is not set or is empty" "$(check_required_env_vars)"
}

function test_check_required_env_vars_empty_username() {
    mock error_and_exit <<< '$1'

    export GCP_VM_HOSTNAME="test-host"
    export GCP_VM_USERNAME=""
    export SSH_PUBLIC_KEY_PATH="$TEST_TMP_DIR/test_key.pub"
    export GCE_PRIVATE_KEY_PATH="$TEST_TMP_DIR/test_key"

    echo "ssh-ed25519 ABC test" > "$SSH_PUBLIC_KEY_PATH"
    echo "-----BEGIN OPENSSH PRIVATE KEY-----" > "$GCE_PRIVATE_KEY_PATH"
    chmod 600 "$GCE_PRIVATE_KEY_PATH"

    assert_same "GCP_VM_USERNAME environment variable is not set or is empty" "$(check_required_env_vars)"
}

function test_check_required_env_vars_missing_ssh_public_key_path() {
    mock error_and_exit <<< '$1'

    export GCP_VM_HOSTNAME="test-host"
    export GCP_VM_USERNAME="testuser"
    unset SSH_PUBLIC_KEY_PATH
    export GCE_PRIVATE_KEY_PATH="$TEST_TMP_DIR/test_key"

    echo "-----BEGIN OPENSSH PRIVATE KEY-----" > "$GCE_PRIVATE_KEY_PATH"
    chmod 600 "$GCE_PRIVATE_KEY_PATH"

    assert_same "SSH_PUBLIC_KEY_PATH environment variable is not set" "$(set +u; check_required_env_vars | head -1)"
}

function test_check_required_env_vars_empty_ssh_public_key_path() {
    mock error_and_exit <<< '$1'

    export GCP_VM_HOSTNAME="test-host"
    export GCP_VM_USERNAME="testuser"
    export SSH_PUBLIC_KEY_PATH=""
    export GCE_PRIVATE_KEY_PATH="$TEST_TMP_DIR/test_key"

    echo "-----BEGIN OPENSSH PRIVATE KEY-----" > "$GCE_PRIVATE_KEY_PATH"
    chmod 600 "$GCE_PRIVATE_KEY_PATH"

    assert_same "SSH_PUBLIC_KEY_PATH environment variable is not set" "$(check_required_env_vars | head -1)"
}

function test_check_required_env_vars_ssh_public_key_nonexistent() {
    mock error_and_exit <<< '$1'

    export GCP_VM_HOSTNAME="test-host"
    export GCP_VM_USERNAME="testuser"
    export SSH_PUBLIC_KEY_PATH="$TEST_TMP_DIR/nonexistent_key.pub"
    export GCE_PRIVATE_KEY_PATH="$TEST_TMP_DIR/test_key"

    echo "-----BEGIN OPENSSH PRIVATE KEY-----" > "$GCE_PRIVATE_KEY_PATH"
    chmod 600 "$GCE_PRIVATE_KEY_PATH"

    assert_same "SSH public key file at $SSH_PUBLIC_KEY_PATH is not readable or does not exist" "$(check_required_env_vars)"
}

function test_check_required_env_vars_ssh_public_key_unreadable() {
    mock error_and_exit <<< '$1'

    export GCP_VM_HOSTNAME="test-host"
    export GCP_VM_USERNAME="testuser"
    export SSH_PUBLIC_KEY_PATH="$TEST_TMP_DIR/unreadable_key.pub"
    export GCE_PRIVATE_KEY_PATH="$TEST_TMP_DIR/test_key"

    echo "ssh-ed25519 ABC test" > "$SSH_PUBLIC_KEY_PATH"
    chmod 000 "$SSH_PUBLIC_KEY_PATH"
    echo "-----BEGIN OPENSSH PRIVATE KEY-----" > "$GCE_PRIVATE_KEY_PATH"
    chmod 600 "$GCE_PRIVATE_KEY_PATH"

    assert_same "SSH public key file at $SSH_PUBLIC_KEY_PATH is not readable or does not exist" "$(check_required_env_vars)"
}

function test_check_required_env_vars_missing_gce_private_key_path() {
    mock error_and_exit <<< '$1'

    export GCP_VM_HOSTNAME="test-host"
    export GCP_VM_USERNAME="testuser"
    export SSH_PUBLIC_KEY_PATH="$TEST_TMP_DIR/test_key.pub"
    unset GCE_PRIVATE_KEY_PATH

    echo "ssh-ed25519 ABC test" > "$SSH_PUBLIC_KEY_PATH"

    assert_same "GCE_PRIVATE_KEY_PATH environment variable is not set" "$(set +u; check_required_env_vars | head -1)"
}

function test_check_required_env_vars_empty_gce_private_key_path() {
    mock error_and_exit <<< '$1'

    export GCP_VM_HOSTNAME="test-host"
    export GCP_VM_USERNAME="testuser"
    export SSH_PUBLIC_KEY_PATH="$TEST_TMP_DIR/test_key.pub"
    export GCE_PRIVATE_KEY_PATH=""

    echo "ssh-ed25519 ABC test" > "$SSH_PUBLIC_KEY_PATH"

    assert_same "GCE_PRIVATE_KEY_PATH environment variable is not set" "$(check_required_env_vars | head -1)"
}

function test_check_required_env_vars_gce_private_key_nonexistent() {
    mock error_and_exit <<< '$1'

    export GCP_VM_HOSTNAME="test-host"
    export GCP_VM_USERNAME="testuser"
    export SSH_PUBLIC_KEY_PATH="$TEST_TMP_DIR/test_key.pub"
    export GCE_PRIVATE_KEY_PATH="$TEST_TMP_DIR/nonexistent_private_key"

    echo "ssh-ed25519 ABC test" > "$SSH_PUBLIC_KEY_PATH"

    assert_same "'gcloud compute ssh' private key file at $GCE_PRIVATE_KEY_PATH is not readable or does not exist" "$(check_required_env_vars)"
}

function test_check_required_env_vars_gce_private_key_unreadable() {
    mock error_and_exit <<< '$1'

    export GCP_VM_HOSTNAME="test-host"
    export GCP_VM_USERNAME="testuser"
    export SSH_PUBLIC_KEY_PATH="$TEST_TMP_DIR/test_key.pub"
    export GCE_PRIVATE_KEY_PATH="$TEST_TMP_DIR/unreadable_private_key"

    echo "ssh-ed25519 ABC test" > "$SSH_PUBLIC_KEY_PATH"
    echo "-----BEGIN OPENSSH PRIVATE KEY-----" > "$GCE_PRIVATE_KEY_PATH"
    chmod 000 "$GCE_PRIVATE_KEY_PATH"

    assert_same "'gcloud compute ssh' private key file at $GCE_PRIVATE_KEY_PATH is not readable or does not exist" "$(check_required_env_vars)"
}

function test_check_secrets_files_valid() {
    export GCP_VM_HOSTNAME="test-host"

    local example_secrets="$TEST_TMP_DIR/secrets/gcp_example.yaml"
    local hostname_secrets="$TEST_TMP_DIR/secrets/gcp_test-host.yaml"

    mkdir -p "$TEST_TMP_DIR/secrets"
    echo "example: content" > "$example_secrets"
    echo "hostname: specific content" > "$hostname_secrets"

    # Mock REPO_DIR for this test
    local original_repo_dir="$REPO_DIR"
    REPO_DIR="$TEST_TMP_DIR"

    check_secrets_files
    assert_true $?

    # Restore REPO_DIR
    REPO_DIR="$original_repo_dir"
}

function test_check_secrets_files_missing_example() {
    export GCP_VM_HOSTNAME="test-host"

    local original_repo_dir="$REPO_DIR"
    REPO_DIR="$TEST_TMP_DIR"

    local output=$(check_secrets_files 2>&1 || echo "EXPECTED_EXIT")
    assert_contains "$output" "does not exist"
    assert_contains "$output" "EXPECTED_EXIT"

    REPO_DIR="$original_repo_dir"
}


# ============================================================================
# File Editing Helper Function Tests
# ============================================================================

function test_write_machine_specific_config_into_placeholders() {
    export GCP_VM_HOSTNAME="test-host"
    export GCP_VM_USERNAME="testuser"
    export SSH_PUBLIC_KEY_PATH="$TEST_TMP_DIR/test_key.pub"

    # Create SSH public key file
    echo "ssh-ed25519 AAAAC3 test@example.com" > "$SSH_PUBLIC_KEY_PATH"

    # Mock REPO_DIR for this test
    local original_repo_dir="$REPO_DIR"
    REPO_DIR="$TEST_TMP_DIR"

    # Create the directory structure and config file
    mkdir -p "$TEST_TMP_DIR/gcp/test-host"
    cat > "$TEST_TMP_DIR/gcp/test-host/my-config.nix" << 'EOF'
{
  networking.hostName = "GCP_VM_HOSTNAME_PLACEHOLDER";
  users.users.GCP_VM_USERNAME_PLACEHOLDER = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "SSH_PUBLIC_KEY_PLACEHOLDER"
    ];
  };
}
EOF

    write_machine_specific_config_into_placeholders

    # Verify placeholders were replaced correctly
    local config_content="$(cat "$TEST_TMP_DIR/gcp/test-host/my-config.nix")"

    assert_contains 'networking.hostName = "test-host";' "$config_content"
    assert_contains "users.users.testuser" "$config_content"
    assert_contains "ssh-ed25519 AAAAC3 test@example.com" "$config_content"

    # Verify no placeholders remain
    assert_not_contains "GCP_VM_HOSTNAME_PLACEHOLDER" "$config_content"
    assert_not_contains "GCP_VM_USERNAME_PLACEHOLDER" "$config_content"
    assert_not_contains "SSH_PUBLIC_KEY_PLACEHOLDER" "$config_content"

    # Verify no .bak files were left behind
    assert_file_not_exists "$TEST_TMP_DIR/gcp/test-host/my-config.nix.bak"

    # Restore REPO_DIR
    REPO_DIR="$original_repo_dir"
}

# ============================================================================
# Utility Function Tests
# ============================================================================

function test_cleanup_tmp_dir_with_existing_directory() {
    local test_dir="$TEST_TMP_DIR/test_cleanup"
    mkdir -p "$test_dir"
    echo "test content" > "$test_dir/test_file"

    # Verify directory exists
    assert_directory_exists "$test_dir"
    assert_file_exists "$test_dir/test_file"

    cleanup_tmp_dir "$test_dir"

    # Verify directory is removed
    assert_directory_not_exists "$test_dir"
}

function test_cleanup_tmp_dir_with_nonexistent_directory() {
    local nonexistent_dir="$TEST_TMP_DIR/nonexistent"

    # Should not error when directory doesn't exist
    cleanup_tmp_dir "$nonexistent_dir"
    assert_true $?
}

function test_cleanup_tmp_dir_with_empty_path() {
    # Should not error with empty path
    cleanup_tmp_dir ""
    assert_true $?
}

function test_copy_function() {
    local source_file="$TEST_TMP_DIR/source.txt"
    local dest_file="$TEST_TMP_DIR/dest.txt"

    echo "test content" > "$source_file"
    chmod 644 "$source_file"

    copy "$source_file" "$dest_file"

    assert_file_exists "$dest_file"
    assert_same "test content" "$(cat "$dest_file")"

    # Verify permissions are preserved
    local source_perms=$(stat -c "%a" "$source_file" 2>/dev/null || stat -f "%A" "$source_file" | cut -c4-6)
    local dest_perms=$(stat -c "%a" "$dest_file" 2>/dev/null || stat -f "%A" "$dest_file" | cut -c4-6)
    assert_same "$source_perms" "$dest_perms"
}

# ============================================================================
# Age Key Management Function Tests
# ============================================================================

function test_validate_age_key_valid_key() {
    local valid_key="AGE-SECRET-KEY-12345"

    validate_age_key "$valid_key"
    assert_true $?
}

function test_validate_age_key_empty_key() {
    mock error_and_exit <<< '$1'

    assert_same "No age private key provided" "$(validate_age_key "" | head -1)"
}

function test_validate_age_key_invalid_format() {
    mock error_and_exit <<< '$1'

    local invalid_key="INVALID-KEY-FORMAT"

    assert_same "Invalid age private key format (should start with 'AGE-SECRET-KEY-')" "$(validate_age_key "$invalid_key")"
}

function test_prepare_age_key_file() {
    local tree_dir="$TEST_TMP_DIR/test_tree"
    local valid_key="AGE-SECRET-KEY-123456"

    mkdir -p "$tree_dir"

    prepare_age_key_file "$tree_dir" "$valid_key"

    local age_key_file="$tree_dir/root/.config/sops/age/keys.txt"
    assert_file_exists "$age_key_file"
    assert_same "$valid_key" "$(cat "$age_key_file")"

    # Verify file permissions are restrictive (600)
    local file_perms=$(stat -c "%a" "$age_key_file" 2>/dev/null || stat -f "%A" "$age_key_file" | cut -c4-6)
    assert_same "600" "$file_perms"
}

function test_prepare_age_key_file_creates_directory_structure() {
    local tree_dir="$TEST_TMP_DIR/test_tree_new"
    local valid_key="AGE-SECRET-KEY-ABCDEFGHI"

    # Directory doesn't exist initially
    assert_directory_not_exists "$tree_dir"

    prepare_age_key_file "$tree_dir" "$valid_key"

    # Verify directory structure is created
    assert_directory_exists "$tree_dir/root"
    assert_directory_exists "$tree_dir/root/.config"
    assert_directory_exists "$tree_dir/root/.config/sops"
    assert_directory_exists "$tree_dir/root/.config/sops/age"

    local age_key_file="$tree_dir/root/.config/sops/age/keys.txt"
    assert_file_exists "$age_key_file"
}

# ============================================================================
# File Preparation Function Tests
# ============================================================================

function test_copy_nixos_config() {
    local dest_dir="$TEST_TMP_DIR/nixos_config_dest"

    # Create mock source files
    local original_repo_dir="$REPO_DIR"
    REPO_DIR="$TEST_TMP_DIR"

    # Create source structure
    echo "flake content" > "$TEST_TMP_DIR/flake.nix"
    echo "lock content" > "$TEST_TMP_DIR/flake.lock"
    echo "sops config" > "$TEST_TMP_DIR/.sops.yaml"

    mkdir -p "$TEST_TMP_DIR/gcp/test-config"
    echo "gcp config" > "$TEST_TMP_DIR/gcp/test-config/config.nix"

    mkdir -p "$TEST_TMP_DIR/secrets"
    echo "secret data" > "$TEST_TMP_DIR/secrets/test.yaml"

    mkdir -p "$TEST_TMP_DIR/modules"
    echo "shared module" > "$TEST_TMP_DIR/modules/core.nix"

    copy_nixos_config "$dest_dir"

    # Verify all files are copied
    assert_file_exists "$dest_dir/flake.nix"
    assert_file_exists "$dest_dir/flake.lock"
    assert_file_exists "$dest_dir/.sops.yaml"
    assert_file_exists "$dest_dir/gcp/test-config/config.nix"
    assert_file_exists "$dest_dir/secrets/test.yaml"
    assert_file_exists "$dest_dir/modules/core.nix"

    # Verify content is copied correctly
    assert_same "flake content" "$(cat "$dest_dir/flake.nix")"
    assert_same "secret data" "$(cat "$dest_dir/secrets/test.yaml")"

    # Restore REPO_DIR
    REPO_DIR="$original_repo_dir"
}

# ============================================================================
# NixOS Installation Function Tests
# ============================================================================

function test_run_nixos_anywhere_with_mocked_commands() {
    local test_tree_dir="$TEST_TMP_DIR/test_tree"
    mkdir -p "$test_tree_dir"

    export GCP_VM_HOSTNAME="test-host"
    export GCE_PRIVATE_KEY_PATH="$TEST_TMP_DIR/test_key"
    echo "-----BEGIN OPENSSH PRIVATE KEY-----" > "$GCE_PRIVATE_KEY_PATH"

    # Test that the function attempts to call expected commands by mocking them
    local called_commands_log="$TEST_TMP_DIR/called_commands"
    touch "$called_commands_log"

    local nix_args_file="$TEST_TMP_DIR/nix_args"
    touch "$nix_args_file"

    # Mock the key commands to track calls
    mise() {
        echo "mise $*" >> "$called_commands_log"
        case "$*" in
            "exec pulumi -- pulumi stack output projectId")
                echo "test-project"
                ;;
            "exec pulumi -- pulumi stack output deployedZone")
                echo "us-central1-a"
                ;;
            "exec pulumi -- pulumi stack output instanceName")
                echo "test-instance"
                ;;
            "exec gcloud -- gcloud compute instances describe"*)
                echo "1234567890"
                ;;
            "which gcloud")
                echo "/usr/bin/gcloud"
                ;;
        esac
    }

    nix() {
        echo "nix $*" >> "$called_commands_log"
        if [[ "$1" == "run" && "$2" == "github:nix-community/nixos-anywhere" ]]; then
            echo "$@" > "$nix_args_file"
            echo "Mock nixos-anywhere execution"
            return 0
        fi
    }

    mktemp() {
        echo "$TEST_TMP_DIR/mock_proxy_script"
    }

    # Run the function
    run_nixos_anywhere "$test_tree_dir" >/dev/null 2>&1

    # Verify expected commands were called
    local commands_called_log="$(cat "$called_commands_log")"
    assert_contains "mise exec pulumi -- pulumi stack output projectId" "$commands_called_log"
    assert_contains "mise exec pulumi -- pulumi stack output deployedZone" "$commands_called_log"
    assert_contains "mise exec pulumi -- pulumi stack output instanceName" "$commands_called_log"
    assert_contains "nix run github:nix-community/nixos-anywhere" "$commands_called_log"

    # Verify the nix command arguments
    local nix_args="$(cat "$nix_args_file")"
    assert_contains "--flake .#$GCP_VM_HOSTNAME-first-install" "$nix_args"
    assert_contains "--target-host root@compute.1234567890" "$nix_args"
    assert_contains "--build-on remote" "$nix_args"
    assert_contains "ProxyCommand=$TEST_TMP_DIR/mock_proxy_script" "$nix_args"
    assert_contains "HostKeyAlias=compute.1234567890" "$nix_args"
    assert_contains "CheckHostIP=no" "$nix_args"
    assert_contains "HashKnownHosts=no" "$nix_args"
    assert_contains "ProxyUseFdpass=no" "$nix_args"
    assert_contains "StrictHostKeyChecking=accept-new" "$nix_args"
    assert_contains "-i $GCE_PRIVATE_KEY_PATH" "$nix_args"
    assert_contains "--extra-files $test_tree_dir" "$nix_args"
    assert_contains "--debug" "$nix_args"
    assert_contains "--show-trace" "$nix_args"
}
