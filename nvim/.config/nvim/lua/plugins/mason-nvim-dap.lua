local function configure_mason_nvim_dap()
  require('mason-nvim-dap').setup({
    ensure_installed = {
      'codelldb',
    },
  })
end

return {
  'jay-babu/mason-nvim-dap.nvim',
  config = configure_mason_nvim_dap,
  event = 'VeryLazy',
  dependencies = {
    { 'mfussenegger/nvim-dap' },
    { 'williamboman/mason.nvim' },
  },
}
