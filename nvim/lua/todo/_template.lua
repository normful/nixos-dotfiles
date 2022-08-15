local utils = require('utils')

local function configure()
  local globals = require('globals')
  if not vim.tbl_contains(globals.fts_enabled, 'plantuml') then return end

  local g = vim.g
  g.somesetting = {}

  local set = utils.set
  set('showtabline', 2)

  utils.nnoremap_silent_bulk({
    ['<Leader>zzz'] = '<Cmd>BufOnly<CR>',

    ['<Leader>zzzzz'] = '<Cmd>lua require("plug/_template").funcs.example()<CR>',
  })

  utils.create_augroups({
    template_augroup = {
      {'TermOpen', '*', 'setlocal wrap'},
    },
  })

  vim.cmd 'command! SomeNewCommand'
  vim.cmd('command! SomeNewCommand')
  vim.cmd([[command! SomeNewCommand]])
  vim.cmd([[highlight! ALEErrorSign ctermbg=236 ctermfg=Red]])

  -- Run multiple lines of vimscript and save result
  local exec_result = vim.api.nvim_exec([[
    highlight! ALEErrorSign ctermbg=236 ctermfg=Red
  ]], true)

  -- Run multiple lines of vimscript without result
  vim.api.nvim_exec([[
    highlight! ALEErrorSign ctermbg=236 ctermfg=Red
    highlight! ALEErrorSign ctermbg=236 ctermfg=Red
    highlight! ALEErrorSign ctermbg=236 ctermfg=Red
  ]], false)

  print("THIS TEMPLATE SHOULD NOT RUN")
end

return {
  -- Non-packer elements
  name = '',
  configure = configure,
  funcs = { example = function() print("example only") end }, -- Export lua funcs to call from Vimscript. See above

  -- Packer elements
  disable = true,
  template = true,
  ft = utils.enabled_fts({'ft1_this_plugin_works_for', 'ft2_this_plugin_works_for'}),
  requires = { {'coot/CRDispatcher'}, {'vim-scripts/BufOnly.vim'}, },
}
