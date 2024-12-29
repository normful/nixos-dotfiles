local wezterm = require('wezterm')
local config = wezterm.config_builder()
local act = wezterm.action

----------------------------
-- Keyboard Mappings
----------------------------

config.disable_default_key_bindings = false
config.leader = { mods = 'CTRL', key = 'a', timeout_milliseconds = 500 }
config.keys = {
  -- Reload config
  { mods = 'CMD', key = 'r', action = act.ReloadConfiguration },

  -- Toggle full screen
  { mods = 'CTRL', key = 'F10', action = 'ToggleFullScreen' },

  -- Tabs: open and navigate
  { mods = 'LEADER', key = 'c', action = act.SpawnTab('CurrentPaneDomain') },
  { mods = 'LEADER', key = 'n', action = act.ActivateTabRelative(1) },
  { mods = 'LEADER', key = 'p', action = act.ActivateTabRelative(-1) },

  -- Panes: open
  { mods = 'LEADER', key = 'v', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
  { mods = 'LEADER', key = 's', action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },

  -- Panes: activate
  { mods = 'LEADER', key = 'h', action = act.ActivatePaneDirection('Left') },
  { mods = 'LEADER', key = 'j', action = act.ActivatePaneDirection('Down') },
  { mods = 'LEADER', key = 'k', action = act.ActivatePaneDirection('Up') },
  { mods = 'LEADER', key = 'l', action = act.ActivatePaneDirection('Right') },

  -- Panes: resize
  { mods = 'LEADER', key = 'r', action = act.ActivateKeyTable({ name = 'resize_pane', one_shot = false }) },

  -- Panes: zoom/unzoom
  { mods = 'LEADER', key = 'o', action = act.TogglePaneZoomState },

  -- Panes: close
  { mods = 'LEADER', key = 'x', action = act.CloseCurrentPane({ confirm = true }) },

  { mods = 'CMD', key = '=', action = act.IncreaseFontSize },
  { mods = 'CMD', key = '-', action = act.DecreaseFontSize },

  -- Paste
  { mods = 'CMD', key = 'V', action = act.PasteFrom('Clipboard') },

  -- Send CTRL+C (for quitting some programs)
  { mods = 'CMD', key = 'c', action = act({ SendString = '\x03' }) },

  -- Send CTRL+D (for quitting some programs)
  { mods = 'CMD', key = 'd', action = act({ SendString = '\x04' }) },

  -- Send CTRL+O (for vim/nvim jump motions: https://neovim.io/doc/user/motion.html--jump-motions)
  { mods = 'CMD', key = 'o', action = act({ SendString = '\x0f' }) },

  -- Send CTRL+I (for vim/nvim jump motions: https://neovim.io/doc/user/motion.html--jump-motions)
  { mods = 'CMD', key = 'i', action = act({ SendString = '\t' }) },

  -- Send CTRL+N (for selecting next item in vim completion menu)
  { mods = 'CMD', key = 'n', action = act({ SendString = '\x0e' }) },

  -- Send CTRL+P (for selecting previous item in vim completion menu)
  { mods = 'CMD', key = 'p', action = act({ SendString = '\x10' }) },

  -- Send CTRL+S (for fish pager-toggle-search https://www.youtube.com/watch?v=dnj-Hpg7Qlo&t=20s)
  { mods = 'CMD', key = '`', action = act({ SendString = '\x13' }) },

  -- F-13... were copied from http://aperiodic.net/phil/archives/Geekery/term-function-keys.html

  -- Send F-13
  { mods = 'CMD', key = 'd', action = act({ SendString = '\x1b[25~' }) },

  -- Send F-14
  { mods = 'CMD', key = 'u', action = act({ SendString = '\x1b[26~' }) },

  -- Send F-15
  { mods = 'CMD', key = 'w', action = act({ SendString = '\x1b[28~' }) },

  -- Send F-16
  { mods = 'CMD', key = 'b', action = act({ SendString = '\x1b[29~' }) },

  -- Send F-17
  { mods = 'CMD', key = 'e', action = act({ SendString = '\x1b[31~' }) },

  -- Send F-18
  { mods = 'CMD', key = 'x', action = act({ SendString = '\x1b[32~' }) },

  -----------------------------------------
  -- Keyboard Mappings For Special Features
  -----------------------------------------
  { mods = 'LEADER', key = 't', action = act.QuickSelect },

  -- TODO(norman): Read https://wezfurlong.org/wezterm/copymode.html#configurable-key-assignments
  { mods = 'LEADER', key = '[', action = act.ActivateCopyMode },

  -- TODO(norman): Read https://wezfurlong.org/wezterm/config/launch.html#the-launcher-menu
  -- TODO(norman): Read https://wezfurlong.org/wezterm/quickselect.html
}

config.key_tables = {
  resize_pane = {
    { key = 'LeftArrow', action = act.AdjustPaneSize({ 'Left', 1 }) },
    { key = 'h', action = act.AdjustPaneSize({ 'Left', 1 }) },

    { key = 'RightArrow', action = act.AdjustPaneSize({ 'Right', 1 }) },
    { key = 'l', action = act.AdjustPaneSize({ 'Right', 1 }) },

    { key = 'UpArrow', action = act.AdjustPaneSize({ 'Up', 1 }) },
    { key = 'k', action = act.AdjustPaneSize({ 'Up', 1 }) },

    { key = 'DownArrow', action = act.AdjustPaneSize({ 'Down', 1 }) },
    { key = 'j', action = act.AdjustPaneSize({ 'Down', 1 }) },

    -- Exits the resize pane mode
    { key = 'Escape', action = 'PopKeyTable' },
    { key = 'Enter', action = 'PopKeyTable' },
  },
}

------------------------------
-- Appearance
------------------------------

config.font_size = 20.0
config.font = wezterm.font_with_fallback({
  { family = 'Inconsolata Nerd Font Mono', weight = 'Regular', italic = false },
  { family = 'Symbols Nerd Font Mono', scale = 1 },
})
config.harfbuzz_features = { 'calt=1', 'clig=0', 'liga=0', 'zero', 'ss01' }

-- Visual test text for fonts
-- oO08 iIlL1 g9qCGQ ~-+=>;_
-- â é ù ï ø ç Ã Ē Æ œ
-- {a} (a) [a]
-- [[ ]]
-- (( ))
-- -----------
-- ___________
-- ===========

config.color_scheme = 'Banana Blueberry'

config.adjust_window_size_when_changing_font_size = false
config.enable_tab_bar = true
config.use_fancy_tab_bar = true
config.initial_cols = 200
config.initial_rows = 70
config.window_frame = {
  font = wezterm.font_with_fallback({
    'PragmataPro Mono Liga',
    -- We swap the patched and non-patched font around, otherwise some things are
    -- not correctly displayed, such as: ']]' (two ] ] (without space)).
    'PragmataProMonoLiga Nerd Font',
    'Apple Color Emoji',
  }),
  font_size = 14.0,
}

wezterm.on('update-right-status', function(window)
  local name = window:active_key_table()
  if name then
    name = 'MODE: ' .. name
  end
  window:set_right_status(name or '')
end)

------------------------------
-- Other
------------------------------

return config
