--[[
TODO(norman): Configure any overrides for any particular colorschemes used below

Docs on basic highlight groups
:h group-name
:h highlight-groups

Docs on treesitter highlight groups
:h treesitter-highlight-groups

Show all highlight groups in your current session
:so $VIMRUNTIME/syntax/hitest.vim

Maybe reuse some of:
https://github.com/normful/monokai.nvim/blob/4ab525323d91b0ff1e360fb11dece9fa6411f727/lua/monokai.lua#L418-L532
]]

local function configure_catppuccin()
  require('catppuccin').setup({
    flavour = 'mocha',
    no_italic = true,
    custom_highlights = function(colors)
      -- Color names are the CtpColor in https://github.com/catppuccin/nvim/blob/main/lua/catppuccin/types.lua
      return {}
    end,
    default_integrations = true,
    integrations = {
      -- Plugin highlight groups: https://github.com/catppuccin/nvim/tree/main/lua/catppuccin/groups/integrations
      cmp = true,
      gitsigns = true,
      nvimtree = true,
      treesitter = true,
      notify = true,
      mason = true,
      nvim_surround = true,
      treesitter_context = true,
      ufo = true,
    },
  })
end

local function configure_nightfox()
  require('nightfox').setup({
    options = {
      -- Usually: ~/.local/share/nvim/nightfox-colorscheme-cache
      compile_path = vim.fn.stdpath('data') .. '/nightfox-colorscheme-cache',
    },
    groups = {
      all = {
        -- Palette fields: https://github.com/EdenEast/nightfox.nvim/blob/main/lua/nightfox/palette.lua
        -- Plugin highlight groups: https://github.com/EdenEast/nightfox.nvim/tree/main/lua/nightfox/group/modules
        RainbowDelimiterBlue = { fg = 'palette.blue' },
        RainbowDelimiterCyan = { fg = 'palette.cyan' },
        RainbowDelimiterGreen = { fg = 'palette.green' },
        RainbowDelimiterOrange = { fg = 'palette.orange' },
        RainbowDelimiterRed = { fg = 'palette.red' },
        RainbowDelimiterViolet = { fg = 'palette.magenta' },
        RainbowDelimiterYellow = { fg = 'palette.yellow' },
      },
    },
  })
end

local function configure_monokai_nightasty()
  require('monokai-nightasty').setup({
    dark_style_background = '#000000',
    markdown_header_marks = true,
    on_highlights = function(highlights, colors)
      -- Colors: https://github.com/polirritmico/monokai-nightasty.nvim/blob/main/lua/monokai-nightasty/colors/dark.lua
      -- Plugin highlight groups: https://github.com/polirritmico/monokai-nightasty.nvim/tree/main/lua/monokai-nightasty/highlights
    end,
  })
end

local function configure_everforest()
  require('everforest').setup({
    background = 'hard',
    ui_contrast = 'high',
  })
end

local function configure_tokyodark()
  require('tokyodark').setup({
    custom_highlights = function(_, palette)
      return {
        -- Palette: https://github.com/tiagovla/tokyodark.nvim/blob/master/lua/tokyodark/palette.lua
        RainbowDelimiterBlue = { fg = palette.blue },
        RainbowDelimiterCyan = { fg = palette.cyan },
        RainbowDelimiterGreen = { fg = palette.green },
        RainbowDelimiterOrange = { fg = palette.orange },
        RainbowDelimiterRed = { fg = palette.red },
        RainbowDelimiterViolet = { fg = palette.purple },
        RainbowDelimiterYellow = { fg = palette.yellow },

        TreesitterContextLineNumber = { fg = palette.cyan },
      }
    end,
  })
end

local function configure_nordic()
  require('nordic').setup({
    on_highlight = function(highlights, palette)
      -- Palette: https://github.com/AlexvZyl/nordic.nvim/blob/main/lua/nordic/colors/nordic.lua
      -- Basic highlight groups: https://github.com/AlexvZyl/nordic.nvim/blob/main/lua/nordic/groups/native.lua
      -- Plugin highlight groups: https://github.com/AlexvZyl/nordic.nvim/blob/main/lua/nordic/groups/integrations.lua
      highlights.RainbowDelimiterBlue = { fg = palette.blue0 }
      highlights.RainbowDelimiterCyan = { fg = palette.cyan.dim }
      highlights.RainbowDelimiterGreen = { fg = palette.green.dim }
      highlights.RainbowDelimiterOrange = { fg = palette.orange.bright }
      highlights.RainbowDelimiterRed = { fg = palette.red.bright }
      highlights.RainbowDelimiterViolet = { fg = palette.magenta.bright }
      highlights.RainbowDelimiterYellow = { fg = palette.yellow.bright }
    end,
  })
end

local function configure_styler()
  local styler = require('styler')
  styler.setup({
    themes = {
      gleam = { colorscheme = 'tokyodark', background = 'dark' },
      go = { colorscheme = 'catppuccin-mocha', background = 'dark' },
      lua = { colorscheme = 'tokyodark', background = 'dark' },
      markdown = { colorscheme = 'tokyodark', background = 'dark' },
      norg = { colorscheme = 'duskfox', background = 'dark' },
      typescript = { colorscheme = 'tokyodark', background = 'dark' },
      yaml = { colorscheme = 'nordic', background = 'dark' },
    },
  })

  vim.cmd.colorscheme('tokyodark')
end

return {
  {
    'nvim-lua/plenary.nvim',
    lazy = false,
    priority = 1200,
  },
  {
    'folke/styler.nvim',
    config = configure_styler,
    lazy = false,
    priority = 1100,
  },

  -- The colorschemes below were chosen because
  -- 1. (Mandatory) They visually look appealing for at least one filetype
  -- 2. (Mandatory) They're compatible with folke/styler.nvim because they call `vim.api.nvim_set_hl`
  -- 3. (Mandatory) They have treesitter support
  -- 4. (Ideally) Their lua code contains some LDoc comments
  -- 5. (Ideally) They are customizable, so that colors for additional highlight groups can be configured

  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = false,
    priority = 1090,
    config = configure_catppuccin,
  },
  {
    'EdenEast/nightfox.nvim',
    lazy = false,
    priority = 1080,
    config = configure_nightfox,
  },
  {
    'normful/monokai-nightasty.nvim',
    lazy = false,
    priority = 1070,
    config = configure_monokai_nightasty,
  },
  {
    'neanias/everforest-nvim',
    lazy = false,
    priority = 1060,
    config = configure_everforest,
  },
  {
    'tiagovla/tokyodark.nvim',
    lazy = false,
    priority = 1050,
    config = configure_tokyodark,
  },
  {
    'AlexvZyl/nordic.nvim',
    lazy = false,
    priority = 1040,
    config = configure_nordic,
  },
}
