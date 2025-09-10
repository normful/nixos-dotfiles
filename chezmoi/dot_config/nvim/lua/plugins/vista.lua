local function configure_vista()
  local g = vim.g
  g.vista_sidebar_position = 'vertical topleft'
  g.vista_sidebar_width = 40
  g.vista_sidebar_keepalt = 1
  g.vista_echo_cursor_strategy = 'both'

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'vista_kind',
    group = vim.api.nvim_create_augroup('VistaKindWindowKeybinds', { clear = true }),
    callback = function(args)
      vim.keymap.set('n', '<S-F2>', '<Cmd>Vista!!<CR>', {
        buffer = args.buf,
        noremap = true,
        silent = true,
        desc = 'Close Vista',
      })
    end,
  })
end

return {
  'liuchengxu/vista.vim',
  config = configure_vista,
  keys = {
    {
      '<S-F2>',
      '<Cmd>Vista nvim_lsp<CR>',
      desc = 'Open Vista with LSP symbols',
    },
  },
}
