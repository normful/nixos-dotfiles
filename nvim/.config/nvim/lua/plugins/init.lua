return {
  {
    'normful/monokai.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme monokai]])
    end,
  },
  { 'nvim-lua/plenary.nvim', lazy = false },
}
