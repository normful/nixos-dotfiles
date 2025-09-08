# Conditional Module Imports Implementation Guide

## Overview
This guide explains how to implement conditional module imports in NixOS configurations using `lib.optionals` and custom configuration options. This allows modules to be imported only when specific conditions are met, making configurations more flexible and modular.

## What This Achieves
- Enables conditional loading of NixOS modules based on custom boolean flags
- Reduces system bloat by only including necessary modules
- Creates more maintainable and flexible system configurations
- Allows different feature sets for different deployment scenarios

## Implementation Steps

### Step 1: Understand the Current Structure
The target file is `gcp/coral/configuration.nix` which currently has a static imports list:

```nix
{
  inputs,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    ../../shared-modules/disko-partitions.nix
    ../../shared-modules/core.nix
    ../../shared-modules/nix.nix
    ../../shared-modules/nh.nix
    ../../shared-modules/user.nix
    ../../shared-modules/openssh-server.nix
    ../../shared-modules/security.nix
    ../../shared-modules/tailscale.nix
    ../../shared-modules/vector.nix
    ./my-config.nix
  ];
}
```

### Step 2: Modify the Function Signature
Change the function parameters to include `lib` and `config`:

**Before:**
```nix
{
  inputs,
  ...
}:
```

**After:**
```nix
{ inputs, lib, config, ... }:
```

**Why:** `lib` provides utility functions like `optionals` and `mkOption`, while `config` gives access to the configuration values we'll define.

### Step 3: Create Custom Configuration Options
Add an `options` section before the `imports` to define your custom flags:

```nix
{
  options.my = {
    enableDevelopment = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable development-related modules and tools";
    };

    enableMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable monitoring and observability modules";
    };

    enableGaming = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable gaming-related modules and packages";
    };
  };

  # ... rest of configuration
}
```

**Key Points:**
- `my` is a namespace to avoid conflicts with existing options
- `lib.mkOption` defines a configuration option with type checking
- `type = lib.types.bool` ensures only boolean values are accepted
- `default = false` means features are opt-in by default
- `description` provides documentation for the option

### Step 4: Implement Conditional Imports
Replace the static imports list with a conditional one:

**Before:**
```nix
imports = [
  inputs.disko.nixosModules.disko
  # ... all other modules
];
```

**After:**
```nix
imports = [
  # Core modules - always imported
  inputs.disko.nixosModules.disko
  inputs.sops-nix.nixosModules.sops
  ../../shared-modules/disko-partitions.nix
  ../../shared-modules/core.nix
  ../../shared-modules/nix.nix
  ../../shared-modules/nh.nix
  ../../shared-modules/user.nix
  ../../shared-modules/openssh-server.nix
  ../../shared-modules/security.nix
  ../../shared-modules/tailscale.nix
  ../../shared-modules/vector.nix
  ./my-config.nix
] ++ lib.optionals config.my.enableDevelopment [
  # Development modules - only when enableDevelopment = true
  ../../shared-modules/development.nix
  ../../shared-modules/docker.nix
  ../../shared-modules/vscode-server.nix
] ++ lib.optionals config.my.enableMonitoring [
  # Monitoring modules - only when enableMonitoring = true
  ../../shared-modules/prometheus.nix
  ../../shared-modules/grafana.nix
] ++ lib.optionals config.my.enableGaming [
  # Gaming modules - only when enableGaming = true
  ../../shared-modules/steam.nix
  ../../shared-modules/gaming.nix
];
```

**How `lib.optionals` Works:**
- `lib.optionals condition list` returns `list` if `condition` is true, empty list if false
- The `++` operator concatenates lists together
- This creates a dynamic imports list based on configuration values

### Step 5: Set Configuration Values
To enable features, you can set them in several ways:

**Option A: In the same file (after the options definition):**
```nix
{
  # ... options and imports ...

  config = {
    my.enableDevelopment = true;
    my.enableMonitoring = false;
    # ... other configuration
  };
}
```

**Option B: In my-config.nix:**
```nix
{
  my = {
    enableDevelopment = true;
    enableMonitoring = true;
    enableGaming = false;
  };

  # ... rest of host-specific config
}
```

**Option C: Environment-based (more advanced):**
```nix
config.my.enableDevelopment = builtins.getEnv "ENABLE_DEV" == "true";
```

### Step 6: Complete Example
Here's what the final `gcp/coral/configuration.nix` should look like:

```nix
{ inputs, lib, config, ... }:
{
  options.my = {
    enableDevelopment = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable development-related modules and tools";
    };

    enableMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable monitoring and observability modules";
    };
  };

  imports = [
    # Core modules - always imported
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    ../../shared-modules/disko-partitions.nix
    ../../shared-modules/core.nix
    ../../shared-modules/nix.nix
    ../../shared-modules/nh.nix
    ../../shared-modules/user.nix
    ../../shared-modules/openssh-server.nix
    ../../shared-modules/security.nix
    ../../shared-modules/tailscale.nix
    ../../shared-modules/vector.nix
    ./my-config.nix
  ] ++ lib.optionals config.my.enableDevelopment [
    # Development modules
    ../../shared-modules/development.nix
    ../../shared-modules/docker.nix
  ] ++ lib.optionals config.my.enableMonitoring [
    # Monitoring modules
    ../../shared-modules/monitoring.nix
  ];
}
```

### Step 7: Testing the Changes
After implementing:

1. **Build test:** `nixos-rebuild dry-build --flake .#coral`
2. **Check what modules are included:** The build output will show which modules are being evaluated
3. **Toggle features:** Change the boolean values and rebuild to see different module sets
4. **Verify functionality:** Ensure services/packages from conditional modules work as expected

## Benefits of This Approach
- **Modularity:** Features can be toggled on/off per host
- **Performance:** Unused modules aren't evaluated or included
- **Maintainability:** Clear separation between core and optional functionality
- **Flexibility:** Easy to create different "profiles" (dev, prod, gaming, etc.)
- **Documentation:** Options are self-documenting with descriptions

## Potential Module Categories
Consider organizing conditional imports by:
- **Development:** IDEs, compilers, debug tools
- **Gaming:** Steam, graphics drivers, game launchers
- **Monitoring:** Prometheus, Grafana, alerting
- **Media:** Plex, streaming tools, codecs
- **Work:** VPN clients, work-specific tools
- **Desktop:** GUI applications, window managers

## Notes and Warnings
- Conditional imports are evaluated at build time, not runtime
- Changing these options requires a system rebuild
- Make sure conditional modules actually exist before referencing them
- Consider using meaningful namespaces (not just `my`) for production use
- Test thoroughly after implementation to ensure no circular dependencies
