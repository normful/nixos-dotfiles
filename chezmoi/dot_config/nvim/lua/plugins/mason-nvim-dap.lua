return {
  'jay-babu/mason-nvim-dap.nvim',
  ---@type MasonNvimDapSettings | {}
  opts = {
    ensure_installed = {
      'codelldb',
    },
  },
  event = 'VeryLazy',
  dependencies = {
    { 'mfussenegger/nvim-dap' },
    { 'williamboman/mason.nvim' },
  },
}
