local function configure_gitsigns()
  require('gitsigns').setup({
    signs = {
      add          = { hl = 'Function', text = '+', numhl = 'GitSignsAddNr',    linehl = 'GitSignsAddLn' },
      delete       = { hl = 'Keyword',  text = '_', numhl = 'GitSignsDeleteNr', linehl = 'GitSignsDeleteLn' },
      topdelete    = { hl = 'Keyword',  text = '‾', numhl = 'GitSignsDeleteNr', linehl = 'GitSignsDeleteLn' },
      change       = { hl = 'Boolean',  text = '~', numhl = 'GitSignsChangeNr', linehl = 'GitSignsChangeLn' },
      changedelete = { hl = 'Boolean',  text = '#', numhl = 'GitSignsChangeNr', linehl = 'GitSignsChangeLn' },
    },

    keymaps = {}, -- Clears out default keymaps

    numhl = false,
    linehl = false,

    watch_gitdir = {
      interval = 2000,
    },

    current_line_blame = false,
  })
end

return {
  'lewis6991/gitsigns.nvim',
  config = configure_gitsigns,
  keys = {
    { '<Leader>ga', '<Cmd>lua require("gitsigns").stage_hunk()<CR>' },
    { '<Leader>gu', '<Cmd>lua require("gitsigns").undo_stage_hunk()<CR>' },

    { '<Leader>gA', '<Cmd>lua require("gitsigns").stage_buffer()<CR>' },

    { '<Leader>gn', '<Cmd>lua require("gitsigns").next_hunk()<CR>' },
    { '<Leader>gp', '<Cmd>lua require("gitsigns").prev_hunk()<CR>' },
    { '<Leader>gN', '<Cmd>lua require("gitsigns").prev_hunk()<CR>' },
  },
  event = 'VeryLazy',
}
