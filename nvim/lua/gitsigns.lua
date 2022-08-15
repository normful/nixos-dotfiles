local function configure_gitsigns()
  --[[ TODO(norman): fix
                                                                                                                                                                               
    Error detected while processing /nix/store/5bb0ly1vz6w9dxp3wj354rycwxc1qn3w-init.vim:                                                                         
    line 1582:                                                                                                                                                                   
    W18: Invalid character in group name

    https://github.com/lewis6991/gitsigns.nvim/issues/604

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
  --]]

  utils.nnoremap_silent_bulk({
    ['<Leader>ga'] = '<Cmd>lua require("gitsigns").stage_hunk()<CR>',
    ['<Leader>gu'] = '<Cmd>lua require("gitsigns").undo_stage_hunk()<CR>',

    ['<Leader>gA'] = '<Cmd>lua require("gitsigns").stage_buffer()<CR>',

    ['<Leader>gn'] = '<Cmd>lua require("gitsigns").next_hunk()<CR>',
    ['<Leader>gp'] = '<Cmd>lua require("gitsigns").prev_hunk()<CR>',
    ['<Leader>gN'] = '<Cmd>lua require("gitsigns").prev_hunk()<CR>',
  })
end

configure_gitsigns()
