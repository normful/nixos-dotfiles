local function configure_vista()
  local g = vim.g
  g.vista_sidebar_position = 'vertical topleft'
  g.vista_sidebar_width = 40
  g.vista_sidebar_keepalt = 1

  utils.nnoremap_silent_bulk({
    ['<F2>'] = '<Cmd>Vista nvim_lsp<CR>',
  })
end

configure_vista()
