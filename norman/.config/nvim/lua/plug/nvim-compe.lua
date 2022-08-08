local function configure()
  vim.o.completeopt = 'menuone,noselect,noinsert'

  local utils = require('utils')
  utils.inoremap_silent_expr_bulk({
    ['<C-e>']     = 'compe#close("<C-e>")',
    ['<C-f>']     = 'compe#scroll({ "delta": +4 })',
    ['<C-d>']     = 'compe#scroll({ "delta": -4 })',
  })

  require('compe').setup({
    enabled = true,
    autocomplete = true,
    debug = false,
    min_length = 1,
    preselect = 'disable',
    throttle_time = 80,
    source_timeout = 200,
    incomplete_delay = 400,
    max_abbr_width = 100,
    max_kind_width = 100,
    max_menu_width = 100,
    documentation = true,

    source = {
      path = true,
      buffer = true,
      calc = true,
      nvim_lsp = true,
      nvim_lua = true,
      vsnip = true,
    },
  })
end

return {
  -- Switch to using 'hrsh7th/nvim-cmp' when it's more stable
  name = 'hrsh7th/nvim-compe',
  configure = configure,
}
