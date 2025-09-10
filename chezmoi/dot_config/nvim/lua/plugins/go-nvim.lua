local function configure_go_nvim()
  require('go').setup()
end

return {
  'ray-x/go.nvim',
  dependencies = {
    'ray-x/guihua.lua',
    'neovim/nvim-lspconfig',
    'mfussenegger/nvim-dap',
    'rcarriga/nvim-dap-ui',
    'theHamsta/nvim-dap-virtual-text',
    'nvim-treesitter/nvim-treesitter',
  },
  config = configure_go_nvim,
  ft = { 'go', 'gomod' },
  build = ':lua require("go.install").update_all_sync()',
}
