# Warp Terminal Configuration

This directory contains a comprehensive Warp terminal configuration that replicates your wezterm setup and incorporates your fish shell aliases and git shortcuts as Warp workflows.

## Files Structure

```
.warp/
├── settings.json                    # Main configuration (matches wezterm preferences)
├── keybindings.json                # Keybindings based on wezterm mappings
├── themes/
│   └── wezterm-dark.yaml           # Dark theme matching wezterm colors
├── workflows/
│   └── personal-workflows.yaml     # 60+ workflows from your fish/git config
└── README.md                       # This file
```

## Key Features

### 🔧 Configuration Ported from Wezterm
- **Font**: Inconsolata Nerd Font Mono at 20pt (matching wezterm)
- **Colors**: Custom theme based on your wezterm tab bar colors
- **Window**: Resize-only decorations, tab bar at bottom, 200x70 initial size
- **Performance**: 120 FPS, 100,000 line scrollback
- **Features**: IME support, Kitty keyboard protocol, quick select patterns

### ⌨️ Keybindings Based on Wezterm
- **Leader key concept**: Adapted wezterm's Ctrl+A leader to Cmd-based shortcuts
- **Vim-like navigation**: Cmd+h/j/k/l for pane navigation
- **Tab management**: Cmd+t (new), Cmd+w (close), Cmd+Shift+[/] (navigate)
- **Pane splitting**: Cmd+d (horizontal), Cmd+Shift+d (vertical)
- **Terminal control sequences**: All your custom Ctrl sequences (Ctrl+C, Ctrl+D, etc.)
- **Function keys**: F13-F18 mappings for special applications
- **Quick select**: Cmd+Shift+h for hints mode

### 🚀 60+ Workflows from Your Fish/Git Config

The `personal-workflows.yaml` file contains workflows based on:

#### Fish Shell Abbreviations & Functions
- **File Operations**: Enhanced `ls` with eza, tree view, yazi file manager
- **Directory Navigation**: Directory history, make+cd, disk usage analysis
- **Development Tools**: Cargo commands, npm scripts, Gleam/Zola tools
- **Configuration Editing**: Quick access to edit fish, git, nvim, terminal configs
- **System Management**: Blog building, nix-darwin switching, dotfile stowing
- **Utilities**: Pretty cat, better man pages, UTC time, process management

#### Git Aliases (from ~/.gitconfig)
- **Status & Logging**: `git s` (short status), `git l` (graph log), `git ll` (with stats)
- **Committing**: Quick commit, amend, various commit shortcuts
- **Branching**: Create/checkout branches, checkout last branch, push with upstream
- **Diffing**: Unstaged/staged diffs, show commits, reset operations
- **Advanced**: Interactive rebase, file unstaging, hard reset with safety

#### Additional Workflows
- **Docker**: Container/image management, system pruning
- **Network**: Port checking, connection listing
- **Search**: Ripgrep with fzf, large file finding
- **Process**: Modern process listing with procs, killing by name

## Workflow Usage

### Access Workflows
1. Press `Ctrl+Shift+R` or click the workflow button
2. Type to search (e.g., "git", "cargo", "edit", "tree")
3. Select workflow and fill in parameters
4. Execute with Enter

### Example Workflows
- **"Git Quick Commit"**: `git add --all && git commit -m "{{message}}"`
- **"Edit Fish Config"**: `nvim ~/code/nixos-dotfiles/fish/.config/fish/config.fish`
- **"Tree View"**: `eza --tree ...options... {{path}}`
- **"Cargo Test with Output"**: `cargo test -- --nocapture`

### Parameterized Workflows
Many workflows accept parameters:
- **Git Create Branch**: Enter branch name
- **Edit File**: Specify file path
- **Search**: Enter search query
- **Port Check**: Specify port number

## Installation

### Option 1: Copy to Warp directory
```bash
cp -r .warp/* ~/Library/Application\ Support/dev.warp.Warp-Stable/
```

### Option 2: Symlink (recommended for dotfiles management)
```bash
# Backup existing config
mv ~/Library/Application\ Support/dev.warp.Warp-Stable ~/Library/Application\ Support/dev.warp.Warp-Stable.backup

# Create symlink
ln -sf $(pwd)/.warp ~/Library/Application\ Support/dev.warp.Warp-Stable
```

### Option 3: Individual file symlinks
```bash
WARP_CONFIG="$HOME/Library/Application Support/dev.warp.Warp-Stable"
mkdir -p "$WARP_CONFIG"/{themes,workflows}

ln -sf $(pwd)/.warp/settings.json "$WARP_CONFIG/settings.json"
ln -sf $(pwd)/.warp/keybindings.json "$WARP_CONFIG/keybindings.json"
ln -sf $(pwd)/.warp/themes/wezterm-dark.yaml "$WARP_CONFIG/themes/wezterm-dark.yaml"
ln -sf $(pwd)/.warp/workflows/personal-workflows.yaml "$WARP_CONFIG/workflows/personal-workflows.yaml"
```

## Migration Benefits

### From Fish Abbreviations to Workflows
- **Discoverability**: Search through 60+ commands instead of remembering abbreviations
- **Documentation**: Each workflow has descriptions and parameter help
- **Parameterization**: Interactive parameter entry vs manual typing
- **Cross-terminal**: Works in any Warp session vs shell-specific abbreviations

### From Git Aliases to Workflows
- **Visual Interface**: Browse git commands vs remembering alias names
- **Parameter Guidance**: Helpful prompts for branch names, commit references, etc.
- **Safety**: Clear descriptions prevent accidental destructive operations
- **Learning**: Understand full git commands behind your aliases

### From Wezterm to Warp
- **Enhanced Features**: AI assistance, better command completion
- **Workflow System**: More powerful than aliases or leader key bindings
- **Team Sharing**: Easy to share workflows vs complex terminal configs
- **Regular Updates**: Active development and new features

## Key Differences from Original Setup

| Original | Warp Equivalent | Notes |
|----------|----------------|--------|
| `abbr --add l 'eza ...'` | "List Files (Enhanced)" workflow | Searchable, documented |
| `abbr --add g git` | Multiple git workflows | More granular, parameterized |
| `Ctrl+A` leader in wezterm | `Cmd+` shortcuts | Direct key bindings |
| Fish functions | Warp workflows | Better parameter handling |
| Git aliases | Git workflows | Interactive parameter entry |
| `t` function for tree | "Tree View" workflow | Path parameter with default |

## Notes

- **Restart required**: Warp needs restart after config changes
- **Font dependency**: Install Inconsolata Nerd Font for proper display
- **Fish shell**: Configuration assumes fish at `/opt/homebrew/bin/fish`
- **Path assumptions**: Workflows use your standard paths (`~/code/nixos-dotfiles/`)
- **Workflow updates**: Edit `personal-workflows.yaml` to add/modify workflows

## Customization

- **Add workflows**: Edit `workflows/personal-workflows.yaml`
- **Modify keybindings**: Edit `keybindings.json`
- **Adjust appearance**: Edit `settings.json` or `themes/wezterm-dark.yaml`
- **Create variants**: Copy and modify existing workflows for different use cases

This configuration provides a seamless transition from your current wezterm+fish+git setup to Warp while maintaining familiar functionality and adding powerful new features.
