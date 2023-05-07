local function configure_telescope()
  local normal_and_terminal_mode_mappings = {
    -- [p]reviously opened filenames
    ['<LocalLeader>p'] = '<Cmd>lua require("telescope.builtin").oldfiles()<CR>',

    -- [fi]ind [fi]lenames
    -- TODO(norman)
    -- ['<LocalLeader>f']  = '<Cmd>lua require("plug/telescope").funcs.git_or_find_files()<CR>', -- in this git repo
    -- ['<Leader>fi']      = '<Cmd>lua require("plug/telescope").funcs.git_or_find_files()<CR>', -- in this git repo
    ['<Leader>fia']     = '<Cmd>lua require("telescope.builtin").find_files({cwd="~/code"})<CR>', -- in all code

    -- [gg]rep for text
    ['<LocalLeader>g'] = '<Cmd>ProjectRootCD<CR><Bar><Cmd>lua require("telescope.builtin").live_grep()<CR>', -- in this git repo
    ['<Leader>gg']     = '<Cmd>ProjectRootCD<CR><Bar><Cmd>lua require("telescope.builtin").live_grep()<CR>', -- in this git repo
    ['<Leader>gga']    = '<Cmd>cd ~/code<CR><Bar><Cmd>lua require("telescope.builtin").live_grep()<CR>',    -- in all code

    -- [b]uffers
    ['<LocalLeader>b'] = '<Cmd>lua require("telescope.builtin").buffers()<CR>',
    ['<Leader>b']      = '<Cmd>lua require("telescope.builtin").buffers()<CR>',

    -- [man] pages
    ['<Leader>man'] = '<Cmd>lua require("telescope.builtin").man_pages()<CR>',

    -- [o] [o]pen directory with z[o]xide
    ['<LocalLeader>o'] = '<Cmd>lua require("telescope").extensions.zoxide.list{}<CR>',

    -- [k] boo[k]marks and lin[k]s
    ['<LocalLeader>k'] = '<Cmd>Telescope bookmarks<CR>',
  }

  utils.tnoremap_silent_bulk(normal_and_terminal_mode_mappings)
  utils.nnoremap_silent_bulk(vim.tbl_extend('error', normal_and_terminal_mode_mappings, {
    -- grep for word under cursor
    ['<Leader>vv'] = '><Cmd>lua require("telescope.builtin").grep_string({ cwd = vim.api.nvim_eval("projectroot#get()") })<CR>',

    ['<Leader>lsp'] = '<Cmd>lua require("telescope.builtin").lsp_references()<CR>',

    -- Vim-related
    ['<Leader>vh'] = '<Cmd>lua require("telescope.builtin").help_tags()<CR>',
    ['<Leader>vm'] = '<Cmd>lua require("telescope.builtin").keymaps()<CR>',
    ['<Leader>vau'] = '<Cmd>lua require("telescope.builtin").autocommands()<CR>',
    ['<Leader>vc'] = '<Cmd>lua require("telescope.builtin").commands()<CR>',
    ['<Leader>vhi'] = '<Cmd>lua require("telescope.builtin").highlights()<CR>',
  }))

  local telescope = require('telescope')
  local actions = require('telescope.actions')

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

          ['<C-q>'] = actions.send_to_qflist
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
      bookmarks = {
        selected_browser = 'vivaldi',
      },
    },
  })

  telescope.load_extension('fzy_native')
  telescope.load_extension('zoxide')
  telescope.load_extension('bookmarks')

  local zoxide_utils = require("telescope._extensions.zoxide.utils")
  local zoxide_config = require("telescope._extensions.zoxide.config")
  zoxide_config.setup({
    mappings = {
      ["<CR>"] = { action = zoxide_utils.create_basic_command("split") },
    },
  })
end

configure_telescope()

local function git_or_find_files()
  local builtin = require('telescope.builtin')
  local opts = {}
  local ok = pcall(builtin.git_files, opts)
  if not ok then builtin.find_files(opts) end
end
