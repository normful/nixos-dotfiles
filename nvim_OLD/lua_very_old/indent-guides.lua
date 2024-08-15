local function configure()
  local utils = require('utils')
  local g = vim.g

  g.indent_guides_enable_on_vim_startup = 0
  g.indent_guides_auto_colors = 0

  utils.create_augroups({
    indent_guides_augroup = {
      { 'VimEnter,Colorscheme', '*', ':hi IndentGuidesOdd  guibg=black    ctermbg=black' },
      { 'VimEnter,Colorscheme', '*', ':hi IndentGuidesEven guibg=darkgrey ctermbg=darkgrey' },
    },
  })

  utils.nnoremap_silent_bulk({
    -- Toggle invisible aka hidden characters
    ['<LocalLeader>i'] = ':set list!<CR>:e ++ff=unix<CR>:IndentGuidesToggle<CR>',
  })
end

return {
  name = 'nathanaelkane/vim-indent-guides',
  configure = configure,
}
