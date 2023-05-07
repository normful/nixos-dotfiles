local function configure_vista()
  local g = vim.g
  g.vista_sidebar_position = 'vertical topleft'
  g.vista_sidebar_width = 40
  g.vista_sidebar_keepalt = 1
  g.vista_echo_cursor_strategy = 'both'
end

return {
  'liuchengxu/vista.vim',
  config = configure_vista,
  keys = {
    { '<F2>', '<Cmd>Vista nvim_lsp<CR>' },
  }
}
