# FILES_EXPLANATION.md

This document provides a comprehensive overview of the file structure and explains the purpose of each file in this NixOS dotfiles repository.

## File Tree Structure

```
nixos-dotfiles/
├── README.md                           # Main repository documentation
├── CLAUDE.md                          # AI assistant guidance for this repository
├── FILES_EXPLANATION.md               # This file - explains all files in the repo
├── LICENSE                            # MIT license
├── stylua.toml                        # Lua formatter configuration
├── mise.toml                          # Task runner and environment configuration
├── flake.nix                          # Main Nix flake definition
├── flake.lock                         # Locked dependency versions for reproducibility
├── .sops.yaml                         # SOPS encryption configuration with age keys
├──
├── Pulumi.coral.yaml                  # Pulumi config for the 'coral' GCP VM instance
├── Pulumi.example.yaml                # Template for new Pulumi VM configurations
├──
├── modules/                           # Shared NixOS configuration modules
│   ├── core.nix                       # Base system configuration and essential packages
│   ├── disko-partitions.nix           # Disk partitioning scheme (EFI/swap/root)
│   ├── golang.nix                     # Optional Go development environment
│   ├── nh.nix                         # NixOS Helper configuration
│   ├── nix.nix                        # Nix daemon settings and cache configuration
│   ├── openssh-server.nix             # Hardened SSH server configuration
│   ├── security.nix                   # System security (firewall, fail2ban, polkit)
│   ├── tailscale.nix                  # Mesh VPN configuration with auto-connect
│   ├── user.nix                       # User account management and SSH keys
│   └── vector.nix                     # Log shipping to Google Cloud Logging
├──
├── gcp/                               # Google Cloud Platform infrastructure
│   ├── index.ts                       # Main Pulumi entry point and exports
│   ├── config.ts                      # Configuration validation and environment handling
│   ├── compute.ts                     # VM instances, disks, and resource policies
│   ├── firewall.ts                    # Network security rules
│   ├── iam.ts                         # Identity and access management
│   ├── monitoring.ts                  # Cloud Logging metrics and alerts
│   ├── network.ts                     # VPC, subnets, and Cloud NAT
│   ├── install-nixos.sh               # Automated NixOS installation script
│   ├──
│   ├── coral/                         # Configuration for 'coral' VM instance
│   │   ├── configuration.nix          # Main NixOS configuration with module imports
│   │   └── my-config.nix              # Host-specific settings (project ID, hostname, user)
│   └──
│   └── example/                       # Template files for new VM instances
│       ├── configuration.nix          # Template NixOS configuration
│       └── my-config.nix              # Template host-specific config with placeholders
├──
├── mac/                               # macOS configuration using nix-darwin
│   └── cyan/                          # Configuration for 'cyan' MacBook Pro
│       ├── configuration.nix          # Main nix-darwin configuration
│       └── packages.nix               # macOS-specific package definitions
├──
├── secrets/                           # SOPS-encrypted secret files
│   ├── gcp_coral.yaml                 # Encrypted secrets for 'coral' VM
│   └── gcp_example.yaml               # Template for new VM secret files
├──
└── tests/                             # Test suite
    └── gcp/
        └── install-nixos-test.sh       # Bash unit tests for installation script
```

## File Explanations

### Root Configuration Files

**`README.md`**
- Main documentation explaining the repository purpose and architecture
- Includes FAQs about design decisions (no Home Manager, no VM on macOS)
- Lists current managed machines (`coral` GCP VM, `cyan` MacBook Pro)

**`CLAUDE.md`**
- Guidance document for AI assistants working with this codebase
- Contains common commands, architecture overview, and development workflow
- Not intended for human readers - specifically for AI code assistance

**`LICENSE`**
- MIT license for the repository

**`mise.toml`**
- Configuration for the `mise` task runner (replacement for Make)
- Defines tools: bun, pulumi, gcloud, sops, age
- Environment variables for GCP project, VM hostname, SSH keys
- Task definitions for building, testing, deploying, and managing infrastructure

**`flake.nix`**
- Main Nix flake defining all system configurations
- Supports multiple nixpkgs versions for different stability needs
- Defines both NixOS systems (Linux VMs) and Darwin systems (macOS)
- Entry point for all Nix-related operations

**`flake.lock`**
- Lockfile ensuring reproducible builds by pinning exact dependency versions
- Automatically maintained by Nix when running `nix flake update`

**`.sops.yaml`**
- Configuration for SOPS (Secrets OPerationS) encryption
- Defines age public keys for different systems and use cases
- Specifies encryption rules for different secret file patterns

**`stylua.toml`**
- Configuration for StyLua (Lua code formatter)
- Used for formatting Neovim configuration (managed by chezmoi, not in this repo)

### Pulumi Configuration

**`Pulumi.coral.yaml`**
- Pulumi stack configuration for the production 'coral' VM instance
- Contains GCP project ID, zone, machine types, disk configuration
- Specific settings: Asia Northeast 2 (Osaka), n2d instance types, 60GB disk

**`Pulumi.example.yaml`**
- Template for creating new VM configurations
- Contains placeholder `GCP_PROJECT_ID_PLACEHOLDER` for substitution
- Copied and customized when creating new VM instances with `mise new`

### NixOS Modules (`modules/`)

**`core.nix`**
- Base system configuration applied to all NixOS systems
- Essential packages: curl, git, sops, age, neovim
- SOPS integration for secret management
- Basic system settings: timezone (UTC), locale, editor preferences

**`disko-partitions.nix`**
- Disk partitioning configuration using the Disko tool
- Defines standard layout: EFI System Partition, 2GB swap, ext4 root
- Used by nixos-anywhere for automated disk setup

**`golang.nix`**
- Optional Go development environment module
- Includes Go toolchain, language server (gopls), debugger (delve)
- Disabled by default, can be enabled per-system

**`nh.nix`**
- Configuration for NixOS Helper (nh) tool
- Provides better output formatting for system operations
- Includes nix-output-monitor and nvd for build monitoring

**`nix.nix`**
- Nix daemon configuration and optimization settings
- Cache configuration with community caches (Cachix)
- Garbage collection and store optimization policies

**`openssh-server.nix`**
- Hardened SSH server configuration for VMs
- Key-only authentication, no passwords, limited users
- Ed25519 host keys, X11 forwarding enabled for development

**`security.nix`**
- System security hardening
- Firewall configuration, fail2ban with incremental ban times
- Polkit rules allowing wheel group shutdown/reboot without password

**`tailscale.nix`**
- Tailscale mesh VPN configuration
- Auto-connect on boot with exit node advertising
- SSH integration, encrypted secret management for auth keys

**`user.nix`**
- User account management and SSH key setup
- Automatic SSH keypair generation for system users
- Fish shell configuration, sudo access via wheel group

**`vector.nix`**
- Vector log agent configuration for structured logging
- Reads systemd journal, transforms logs, ships to Google Cloud Logging
- Filters and enriches login events with GCP metadata

### GCP Infrastructure (`gcp/`)

**`index.ts`**
- Main Pulumi entry point that imports all infrastructure modules
- Exports all resource names and important outputs
- Provides a single interface to the entire infrastructure

**`config.ts`**
- Centralized configuration management with validation
- Reads environment variables and Pulumi configuration
- Validates machine types, disk sizes, email formats, SSH keys

**`compute.ts`**
- VM instances, disks, and resource policies
- Supports dual instance sizing (large for install, small for operation)
- Snapshot policies, instance scheduling (auto start/stop)

**`firewall.ts`**
- Network security rules with comprehensive logging
- IAP SSH access, Tailscale P2P communication
- Default-deny rule as security fallback

**`iam.ts`**
- Identity and Access Management configuration
- IAP tunnel access permissions for specific users
- Compute instance admin permissions

**`monitoring.ts`**
- Cloud Logging metrics for login events and SSH connections
- Email alerting for security events and instance lifecycle
- Custom log extraction and metric creation

**`network.ts`**
- VPC, subnets, and Cloud NAT configuration
- Private IP addressing with public NAT for outbound traffic
- Flow logging for network monitoring

**`install-nixos.sh`**
- Automated NixOS installation script using nixos-anywhere
- Handles IAP TCP forwarding for secure remote installation
- Age key management, template substitution, validation

### System-Specific Configurations

**`gcp/coral/` - Production VM Configuration**
- `configuration.nix`: Standard module imports for NixOS VM
- `my-config.nix`: Host-specific settings (hostname, user, SSH keys, GCP project)

**`gcp/example/` - Template for New VMs**
- Template files with placeholders for creating new VM configurations
- `my-config.nix` contains placeholders replaced during installation

**`mac/cyan/` - MacBook Pro Configuration**
- `configuration.nix`: nix-darwin configuration for macOS
- `packages.nix`: macOS-specific package selections and configurations

### Secrets Management (`secrets/`)

**`gcp_coral.yaml`**
- SOPS-encrypted secrets for the coral VM instance
- Contains hashed user passwords and Tailscale authentication keys
- Encrypted with gcp_vm_key and emergency_key

**`gcp_example.yaml`**
- Template for new VM secret files
- Used by `mise new` to create host-specific secret files
- Must be customized with actual secrets before deployment

### Testing (`tests/`)

**`tests/gcp/install-nixos-test.sh`**
- Comprehensive bash unit test suite using bashunit framework
- Tests environment validation, file operations, age key handling
- Mocks external dependencies (Pulumi, gcloud, nix) for isolated testing
- Covers error conditions and edge cases in the installation process

## File Relationships and Workflow

1. **Templates → Instances**: `gcp/example/` and `Pulumi.example.yaml` are copied to create new VM configurations
2. **Modules → Systems**: Files in `modules/` are imported by system configurations in `gcp/` and `mac/`
3. **Secrets → Runtime**: Encrypted files in `secrets/` are decrypted at runtime by SOPS
4. **Infrastructure → Installation**: TypeScript files in `gcp/` define infrastructure, `install-nixos.sh` provisions NixOS
5. **Configuration → Deployment**: All configuration is declarative and version-controlled for reproducible deployments