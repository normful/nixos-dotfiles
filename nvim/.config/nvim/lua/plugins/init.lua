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
    custom_highlights = {},
    default_integrations = true,
    integrations = {
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
      compile_path = vim.fn.stdpath('data') .. '/nightfox', -- Usually: ~/.local/share/nvim/nightfox
    },
    groups = {
      all = {
        RainbowDelimiterBlue = { fg = "palette.blue" },
        RainbowDelimiterCyan = { fg = "palette.cyan" },
        RainbowDelimiterGreen = { fg = "palette.green" },
        RainbowDelimiterOrange = { fg = "palette.orange" },
        RainbowDelimiterRed = { fg = "palette.red" },
        RainbowDelimiterViolet = { fg = "palette.magenta" },
        RainbowDelimiterYellow = { fg = "palette.yellow" },
      },
    },
  })
end

local function configure_monokai_nightasty()
  require('monokai-nightasty').setup({
    dark_style_background = '#000000',
    markdown_header_marks = true,
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
        RainbowDelimiterBlue = { fg = palette.blue },
        RainbowDelimiterCyan = { fg = palette.cyan },
        RainbowDelimiterGreen = { fg = palette.green },
        RainbowDelimiterOrange = { fg = palette.orange },
        RainbowDelimiterRed = { fg = palette.red },
        RainbowDelimiterViolet = { fg = palette.purple },
        RainbowDelimiterYellow = { fg = palette.yellow },
      }
    end,
  })
end

local function configure_nordic()
  require('nordic').setup({})
end

local function configure_styler()
  local styler = require('styler')
  styler.setup({
    themes = {
      gleam = { colorscheme = 'tokyodark', background = 'dark' },
      go = { colorscheme = 'catppuccin-mocha', background = 'dark' },
      lua = { colorscheme = 'terafox', background = 'dark' },
      markdown = { colorscheme = 'tokyodark', background = 'dark' },
      norg = { colorscheme = 'duskfox', background = 'dark' },
      typescript = { colorscheme = 'monokai-nightasty', background = 'dark' },
      yaml = { colorscheme = 'nordic', background = 'dark' },
    },
  })

  -- Set the colorscheme to use for most filetypes by default
  vim.cmd.colorscheme('monokai-nightasty')
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
