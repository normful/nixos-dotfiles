local function configure_indent_blankline()
  local highlight = {
    'RainbowDelimiterViolet',
    'RainbowDelimiterCyan',
    'RainbowDelimiterGreen',
    'RainbowDelimiterBlue',
    'RainbowDelimiterOrange',
    'RainbowDelimiterYellow',
    'RainbowDelimiterRed',
  }

  require('ibl').setup({
    indent = {
      char = '▏',
      priority = 2,
    },
    scope = {
      highlight = highlight,
      show_exact_scope = true,
      priority = 1024,
    },
  })

  local hooks = require('ibl.hooks')
  hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
end

return {
  'lukas-reineke/indent-blankline.nvim',
  config = configure_indent_blankline,
}
