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
-- Appearance: Font
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

------------------------------
-- Appearance: Color scheme
------------------------------

local fav_color_schemes = {
  'Everforest Dark (Gogh)',
  'Nord (Gogh)',
  'One Dark (Gogh)',
  'Sea Shells (Gogh)',
  'Sequoia Moonlight',
  'Sugarplum',
  'Spacedust',
  'Tokyo Night',
}

local random_color_scheme = function()
  return fav_color_schemes[math.random(1, #fav_color_schemes)]
end

local active_color_scheme = random_color_scheme()

config.color_scheme = active_color_scheme

------------------------------
-- Appearance: Tab bar
------------------------------

config.enable_tab_bar = true
config.show_tabs_in_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = true

wezterm.on('update-right-status', function(window, pane)
  -- Each element holds the text for a cell in a "powerline" style << fade
  local cells = {}

  table.insert(cells, 'color_scheme: ' .. active_color_scheme)

  table.insert(cells, window:active_key_table() or 'no mode')

  -- The powerline < symbol
  local LEFT_ARROW = utf8.char(0xe0b3)

  -- The filled in variant of the < symbol
  local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

  -- Color palette for the backgrounds of each cell
  local colors = {
    '#151515',
    '#262626',
    '#151515',
    '#262626',
    '#151515',
    '#262626',
  }

  -- Foreground color for the text across the fade
  local text_fg = '#c0c0c0'

  -- The elements to be formatted
  local elements = {}

  -- How many cells have been formatted
  local num_cells = 0

  -- Translate a cell into elements
  function push(text, is_last)
    local cell_no = num_cells + 1
    table.insert(elements, { Foreground = { Color = text_fg } })
    table.insert(elements, { Background = { Color = colors[cell_no] } })
    table.insert(elements, { Text = ' ' .. text .. ' ' })
    if not is_last then
      table.insert(elements, { Foreground = { Color = colors[cell_no + 1] } })
      table.insert(elements, { Text = SOLID_LEFT_ARROW })
    end
    num_cells = num_cells + 1
  end

  while #cells > 0 do
    local cell = table.remove(cells, 1)
    push(cell, #cells == 0)
  end

  window:set_right_status(wezterm.format(elements))
end)

------------------------------
-- Appearance: Window
------------------------------

config.initial_cols = 200
config.initial_rows = 70

config.window_decorations = 'RESIZE'
config.window_frame = {
  font = wezterm.font_with_fallback({
    'PragmataPro Mono Liga',
    -- We swap the patched and non-patched font around, otherwise some things are
    -- not correctly displayed, such as: ']]' (two ] ] (without space)).
    'PragmataProMonoLiga Nerd Font',
    'Apple Color Emoji',
  }),
  font_size = 14.0,
  -- border_left_width = "0.5cell",
  -- border_right_width = "0.5cell",
  -- border_bottom_height = "0.25cell",
  -- border_top_height = "0.25cell",
  -- border_left_color = "purple",
  -- border_right_color = "purple",
  -- border_bottom_color = "purple",
  -- border_top_color = "purple",
}

config.window_padding = {
  left = '10px',
  right = '0px',
  top = 0,
  bottom = 0,
}

config.adjust_window_size_when_changing_font_size = false

------------------------------
-- Other
------------------------------

config.max_fps = 120
config.audible_bell = 'Disabled'
config.use_ime = true

return config
