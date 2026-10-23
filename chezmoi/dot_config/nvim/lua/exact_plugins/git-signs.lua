return {
  'lewis6991/gitsigns.nvim',
  ---@type Gitsigns.Config | {}
  opts = {
    numhl = false,
    linehl = false,
    watch_gitdir = {
      interval = 2000,
    },
    current_line_blame = false,
  },
  keys = {
    { '<Leader>ga', '<Cmd>lua require("gitsigns").stage_hunk()<CR>', desc = 'git stage hunk' },
    { '<Leader>gu', '<Cmd>lua require("gitsigns").undo_stage_hunk()<CR>', desc = 'git unstage hunk' },

    { '<Leader>gA', '<Cmd>lua require("gitsigns").stage_buffer()<CR>', desc = 'git stage buffer' },

    { '<Leader>gn', '<Cmd>lua require("gitsigns").next_hunk()<CR>', desc = 'git next hunk' },
    { '<Leader>gp', '<Cmd>lua require("gitsigns").prev_hunk()<CR>', desc = 'git prev hunk' },
    { '<Leader>gN', '<Cmd>lua require("gitsigns").prev_hunk()<CR>', desc = 'git prev hunk' },
  },
  event = 'VeryLazy',
}
