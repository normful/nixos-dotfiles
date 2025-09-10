This file provides guidance to AI coding agents when working with code in this repository.

## Common Development Commands

This repository uses `mise` as a task runner with the following key commands:

**Formatting & Validation:**
- `mise run format` (or `mise fmt`) - Run Nix autoformatting using `nixfmt-rfc-style`
- `mise run gcp:check:nix` (or `mise check2`) - Check syntax of Nix configuration
- `mise run gcp:check:pulumi` (or `mise check1`) - Check Pulumi infrastructure TypeScript
- `mise run gcp:test:bash` - Run bashunit tests for the installation script

**System Operations:**
- `mise run cyan` - Apply nix-darwin changes to the macOS system
- `mise run update-flake` - Update Nix flake inputs

**GCP Infrastructure & Deployment:**

- `mise run gcp:new` (or `mise new`) - Create new Pulumi stack for new VM
- `mise run gcp:first-up` (or `mise up1`) - Initial launch with larger instance for NixOS install
- `mise run gcp:up` (or `mise up2`) - Create/update GCP resources with regular instance size
- `mise run gcp:install` (or `mise i`) - Install NixOS on provisioned VM using nixos-anywhere
- `mise run gcp:down` - Delete GCP resources (except protected ones)
- `mise run gcp:info` - Show Pulumi stack outputs (instance details, SSH commands)
- `mise run gcp:edit-secrets` (or `mise secrets`) - Edit SOPS-encrypted secrets for VM

## Architecture Overview

This is a comprehensive NixOS dotfiles repository with three main architectural components:

### 1. Nix Configuration (`flake.nix`)

**Multi-Platform Flake Structure:**
- **NixOS Systems**: Linux VMs on Google Cloud Platform
  - Current system: `coral` (defined in `./gcp/coral/configuration.nix`)
  - Uses modular architecture with shared modules in `./modules/`
- **Darwin Systems**: macOS configuration using nix-darwin
  - Current system: `cyan` MacBook Pro (defined in `./mac/cyan/configuration.nix`)
- **Multi-Version Strategy**: Uses pinned versions of nixpkgs:
  - `nixpkgs-2411`: Stable baseline
  - `nixpkgs-2505`: Newer stable for macOS
  - `nixpkgs-unstable-2511`: Latest packages (Neovim, etc.)

### 2. Infrastructure as Code (`./gcp/`)

**Pulumi TypeScript Infrastructure:**
- **Entry Point**: `./gcp/index.ts` - Exports all resources and outputs
- **Core Modules**:
  - `compute.ts` - VM instances, disks, policies (auto-start/stop, snapshots)
  - `network.ts` - VPC, subnets, Cloud NAT with static IP
  - `firewall.ts` - Security rules (IAP SSH access, Tailscale P2P, deny-all fallback)
  - `iam.ts` - IAP tunnel access and compute admin permissions
  - `monitoring.ts` - Cloud Logging metrics and email alerts for logins/lifecycle events
  - `config.ts` - Centralized configuration validation and environment handling

**VM Provisioning & Installation:**
- `./gcp/install-nixos.sh` - Automated NixOS installation using `nixos-anywhere`
- Uses Identity-Aware Proxy (IAP) TCP forwarding for secure access without public IPs
- Supports dual instance sizing: larger instance for initial install, smaller instance for regular operation

**Template System for New VMs:**
- **Pulumi Config Templates**: `Pulumi.example.yaml` → `Pulumi.${hostname}.yaml`
  - Contains GCP project ID placeholder, zone, machine types, disk config
  - Placeholder substitution: `GCP_PROJECT_ID_PLACEHOLDER` → actual project ID
- **NixOS Config Templates**: `gcp/example/` → `gcp/${hostname}/`
  - `configuration.nix`: Standard module imports (by default, same across all VMs, but customizable)
  - `my-config.nix`: Host-specific config with placeholders for project ID, hostname, username, SSH key. The placeholders are replaced by the `gcp/install-nixos.sh` NixOS installer script.
- **SOPS Secret Templates**: `secrets/gcp_example.yaml` → `secrets/gcp_${hostname}.yaml`
- **Template Instantiation**: `mise new` task creates all initial configuration template file copies

### 3. NixOS Module System (`./modules/`)

**Core System Modules:**
- `core.nix` - Base system config, SOPS secrets, essential packages, hostname management
- `disko-partitions.nix` - Disk partitioning scheme (EFI + swap + ext4 root)
- `nix.nix` - Nix daemon settings, cache configuration, garbage collection
- `user.nix` - User management with SSH key generation, Fish shell, sudo access
- `security.nix` - Firewall, fail2ban, polkit rules for wheel group
- `openssh-server.` - Hardened SSH configuration (key-only auth, limited users)

**Service Integration Modules:**
- `tailscale.nix` - Mesh VPN with auto-connect, exit node advertising, SSH integration
- `vector.nix` - Log agent from https://vector.dev configured read JournalD logs, transform them, and send JSON log records to Google Cloud Logging
- `nh.nix` - NixOS Helper with output monitoring tools

### 4. Secrets Management

**SOPS + Age Encryption:**
- **Age Keys**: Three age public keys defined in `.sops.yaml`, which were created manually in the past:
  - `cyan_key`: For macOS-specific secrets (`secrets/cyan.yaml`)
  - `gcp_vm_key`: For GCP VM secrets (`secrets/gcp_*.yaml`)
  - `emergency_key`: Emergency access key for all secrets
- **Encryption Rules**:
  - `secrets/cyan.yaml`: Encrypted with cyan + emergency keys
  - `secrets/gcp_*.yaml`: Encrypted with gcp_vm + emergency keys
  - `secrets/shared.yaml`: Encrypted with all three keys
- **Template Workflow**: `secrets/gcp_example.yaml` → `secrets/gcp_${hostname}.yaml`
- **Secret Contents**: Hashed user passwords, Tailscale auth keys
- **Validation**: Installation script ensures secrets are host-specific (not identical to example)
- **Age Private Key for GCP instances**: Required during NixOS installs on new GCP instances

### 5. Testing Infrastructure

**Bash Unit Tests** (`./tests/gcp/install-nixos-test.sh`):
- Uses [bashunit](https://bashunit.typeddevs.com) to test the `gcp/install-nixos.sh` script

## Key Configuration Details of GCP virtual machines

**Environment Variables**
- When launching a new GCP instance, environment variables need to be configured in `mise.toml`. See `GCP_USAGE.md` for detailed instructions.

**Configuration of the `coral` GCP instance**
- **Machine Types**: `n2d-highmem-8` (first install), `n2d-highcpu-2` (regular operation)
- **Boot Image**: Ubuntu minimal 25.04 AMD64 (replaced by NixOS during first installation)
- **Storage**: 60GB balanced persistent disk
- **Region/Zone**: asia-northeast2-a (Osaka, Japan)

**Cost Savings Features:**
- Preemptible instances used for reduced costs
- Automated daily start/stop scheduling, to turn off instances in the evening

**Security Features:**
- VMs in private subnets with private IP addresses only
- VMs have no public IP addresses
- SSH access to VMs is only through either:
    - SSH tunnels with IAP TCP forwarding
    - Tailscale SSH
- Shielded VM with integrity monitoring and vTPM
- Comprehensive firewall rules with logging

**Monitoring & Alerting:**
- Email alerts from GCP for logins and starts/stops of instances
- SSH connections monitored through Tailscale logs
- Instance lifecycle events from Cloud Audit logs
- Email alerts for connection attempts and VM state changes
- Custom Cloud Logging metrics with label extraction

## Development Workflow

1. **Configuration Changes**: Edit Nix files → `mise check2`
2. **Infrastructure Updates**: Edit TypeScript → `mise check1`
3. **Testing**: `mise run gcp:test:bash` to run Bash script unit tests

## Important Notes

- **Dotfiles**: Managed by chezmoi in the `chezmoi` folder
- **Secret Management**: Humans should always use `mise secrets` to edit encrypted files. AI agents (such as Claude) should not attempt to edit secret files.
