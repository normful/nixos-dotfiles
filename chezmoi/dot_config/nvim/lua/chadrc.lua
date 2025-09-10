-- This file needs to have same structure as
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

M.base46 = {
  -- <Leader>zth opens the theme picker
  theme = 'tokyodark',
  ---@type HLTable
  hl_add = {
    RainbowDelimiterBlue = { fg = 'blue' },
    RainbowDelimiterCyan = { fg = 'cyan' },
    RainbowDelimiterGreen = { fg = 'green' },
    RainbowDelimiterOrange = { fg = 'orange' },
    RainbowDelimiterRed = { fg = 'red' },
    RainbowDelimiterViolet = { fg = 'purple' },
    RainbowDelimiterYellow = { fg = 'yellow' },
    TreesitterContextLineNumber = { fg = 'cyan' },
  },
}

M.ui = {
  cmp = {
    lspkind_text = true,
    style = 'default',
    format_colors = {
      tailwind = true,
    },
  },
  telescope = {
    style = 'bordered',
  },
  statusline = {
    theme = 'minimal',
  },
  tabufline = {
    lazyload = true,
    order = { 'treeOffset', 'buffers', 'tabs' },
  },
}

M.nvdash = {
  load_on_startup = false,
}

return M
