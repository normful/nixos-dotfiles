local function configure_gitsigns()
  require('gitsigns').setup({
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
