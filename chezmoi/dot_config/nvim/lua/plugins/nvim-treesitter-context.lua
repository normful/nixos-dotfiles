local function configure_treesitter_context()
  vim.api.nvim_set_hl(0, 'TreesitterContextBottom', { underline = true, sp = 'Gray' })

  require('treesitter-context').setup()
end

return {
  'nvim-treesitter/nvim-treesitter-context',
  dependencies = {
    { 'nvim-treesitter/nvim-treesitter' },
  },
  config = configure_treesitter_context,
  event = 'VeryLazy',
}
