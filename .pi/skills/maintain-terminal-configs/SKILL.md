---
name: maintain-terminal-configs
description: Maintain synchronized keybindings across Ghostty, WezTerm, and Kitty terminal configs. Use when editing any terminal emulator configuration file, adding new keybindings, or ensuring consistency across terminals.
---

# Terminal Config Maintenance

These three terminal configs share synchronized keybindings. Changes must propagate across all files to preserve muscle memory.

## File Locations

| Terminal | Path |
|----------|------|
| Ghostty | `chezmoi/dot_config/ghostty/config` |
| WezTerm | `chezmoi/dot_config/wezterm/wezterm.lua.tmpl` |
| Kitty | `chezmoi/dot_config/kitty/kitty.conf` |


## Core Rules

1. **One change, three files** — Any keybinding edit must be applied to all three configs
2. **No inline comments** in Ghostty or Kitty keybind lines (breaks parsing)
3. **Leader prefix is Ctrl+A** across all terminals (tmux-style navigation)
4. **CMD keys send to Neovim** via function keys F-13 through F-19

## Platform Conditionals (WezTerm Only)

WezTerm uses chezmoi templates for cross-platform support:

```lua
{ mods = '{{- if .windows }}ALT{{- else }}CMD{{- end }}', key = 'r', ... }
```

- macOS: CMD key
- Windows: ALT key (WSL environment)

Always use the template conditional, never hardcode CMD or ALT.

## Do Not Sync

These are terminal-specific and should remain different:
- **Font sizes**
- **Font families**
- **Themes**
- **Cursor effects**
- **Layout engines**
