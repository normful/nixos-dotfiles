local function configure_table_mode()
  vim.g.table_mode_corner = '|'
end

return {
  'dhruvasagar/vim-table-mode',
  config = configure_table_mode,
  event = 'VeryLazy',
}
