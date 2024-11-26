local function configure_telescope()
  local telescope = require('telescope')
  local actions = require('telescope.actions')
  local browser_bookmarks = require('browser_bookmarks')
  browser_bookmarks.setup({
    selected_browser = 'vivaldi',
  })

  telescope.setup({
    defaults = {
      -- Setting vimgrep_arguments to use a custom rg command seems to cause errors, so don't set it.

      mappings = {
        i = {
          ['<Esc>'] = actions.close,

          -- Left results window scrolling
          ['<C-j>'] = actions.move_selection_next,
          ['<C-k>'] = actions.move_selection_previous,

          -- Right preview window scrolling
          ['<S-j>'] = actions.preview_scrolling_down,
          ['<S-k>'] = actions.preview_scrolling_up,

          ['<C-q>'] = actions.send_to_qflist,
        },
      },
      file_sorter = require('telescope.sorters').get_fzy_sorter,
      prompt_prefix = ' >',
    },
    extensions = {
      fzy_native = {
        override_generic_sorter = true,
        override_file_sorter = true,
      },
    },
  })

  telescope.load_extension('fzy_native')
  telescope.load_extension('zoxide')
  telescope.load_extension('bookmarks')

  local zoxide_utils = require('telescope._extensions.zoxide.utils')
  local zoxide_config = require('telescope._extensions.zoxide.config')
  zoxide_config.setup({
    mappings = {
      ['<CR>'] = { action = zoxide_utils.create_basic_command('split') },
    },
  })
end

return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    { 'jvgrootveld/telescope-zoxide' },
    { 'nvim-telescope/telescope-fzy-native.nvim' },
    { 'dhruvmanila/telescope-bookmarks.nvim' },
  },
  config = configure_telescope,
  keys = {
    -- [p]reviously opened filenames
    { '<LocalLeader>p', '<Cmd>lua require("telescope.builtin").oldfiles()<CR>', mode = 'n' },
    { '<LocalLeader>p', '<Cmd>lua require("telescope.builtin").oldfiles()<CR>', mode = 't' },

    -- [fi]ind [fi]lenames

    -- find filenames in this git repo
    { '<LocalLeader>f', '<Cmd>lua require("plug/telescope").funcs.git_or_find_files()<CR>', mode = 'n' },
    { '<LocalLeader>f', '<Cmd>lua require("plug/telescope").funcs.git_or_find_files()<CR>', mode = 't' },
    { '<Leader>fi', '<Cmd>lua require("plug/telescope").funcs.git_or_find_files()<CR>', mode = 'n' },
    { '<Leader>fi', '<Cmd>lua require("plug/telescope").funcs.git_or_find_files()<CR>', mode = 't' },

    -- find filenames in all code
    { '<Leader>fia', '<Cmd>lua require("telescope.builtin").find_files({cwd="~/code"})<CR>', mode = 'n' },
    { '<Leader>fia', '<Cmd>lua require("telescope.builtin").find_files({cwd="~/code"})<CR>', mode = 't' },

    -- [gg]rep for text

    -- grep for text in this git repo
    {
      '<LocalLeader>g',
      '<Cmd>ProjectRootCD<CR><Bar><Cmd>lua require("telescope.builtin").live_grep()<CR>',
      mode = 'n',
    },
    {
      '<LocalLeader>g',
      '<Cmd>ProjectRootCD<CR><Bar><Cmd>lua require("telescope.builtin").live_grep()<CR>',
      mode = 't',
    },

    -- grep for text in this git repo
    {
      '<Leader>g',
      '<Cmd>ProjectRootCD<CR><Bar><Cmd>lua require("telescope.builtin").live_grep()<CR>',
      mode = 'n',
    },
    {
      '<Leader>g',
      '<Cmd>ProjectRootCD<CR><Bar><Cmd>lua require("telescope.builtin").live_grep()<CR>',
      mode = 't',
    },

    -- grep for text in all git repos
    { '<Leader>gga', '<Cmd>cd ~/code<CR><Bar><Cmd>lua require("telescope.builtin").live_grep()<CR>', mode = 'n' },
    { '<Leader>gga', '<Cmd>cd ~/code<CR><Bar><Cmd>lua require("telescope.builtin").live_grep()<CR>', mode = 't' },

    -- [b]uffers
    { '<LocalLeader>b', '<Cmd>lua require("telescope.builtin").buffers()<CR>', mode = 'n' },
    { '<LocalLeader>b', '<Cmd>lua require("telescope.builtin").buffers()<CR>', mode = 't' },
    { '<Leader>b', '<Cmd>lua require("telescope.builtin").buffers()<CR>', mode = 'n' },
    { '<Leader>b', '<Cmd>lua require("telescope.builtin").buffers()<CR>', mode = 't' },

    -- [man] pages
    { '<Leader>man', '<Cmd>lua require("telescope.builtin").man_pages()<CR>', mode = 'n' },
    { '<Leader>man', '<Cmd>lua require("telescope.builtin").man_pages()<CR>', mode = 't' },

    -- [o]pen directory with z[o]xide
    { '<LocalLeader>o', '<Cmd>lua require("telescope").extensions.zoxide.list{}<CR>', mode = 'n' },
    { '<LocalLeader>o', '<Cmd>lua require("telescope").extensions.zoxide.list{}<CR>', mode = 't' },

    -- boo[k]marks and lin[k]s
    { '<LocalLeader>k', '<Cmd>Telescope bookmarks<CR>', mode = 'n' },
    { '<LocalLeader>k', '<Cmd>Telescope bookmarks<CR>', mode = 't' },

    -- nvim-notify notifications
    { '<LocalLeader>n', '<Cmd>lua require("telescope").extensions.notify.notify()<CR>', mode = 'n' },

    -----------------------------------------
    -- Mappings below are for mode = 'n' only
    -----------------------------------------

    -- grep for word under cursor
    {
      '<Leader>vv',
      '><Cmd>lua require("telescope.builtin").grep_string({ cwd = vim.api.nvim_eval("projectroot#get()") })<CR>',
    },

    { '<Leader>lsp', '<Cmd>lua require("telescope.builtin").lsp_references()<CR>' },

    -- Vim-related
    { '<Leader>vh', '<Cmd>lua require("telescope.builtin").help_tags()<CR>' },
    { '<Leader>vm', '<Cmd>lua require("telescope.builtin").keymaps()<CR>' },
    { '<Leader>vau', '<Cmd>lua require("telescope.builtin").autocommands()<CR>' },
    { '<Leader>vc', '<Cmd>lua require("telescope.builtin").commands()<CR>' },
    { '<Leader>vhi', '<Cmd>lua require("telescope.builtin").highlights()<CR>' },
  },
}
