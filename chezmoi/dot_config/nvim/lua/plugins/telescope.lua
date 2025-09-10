local function configure_telescope()
  local browser_bookmarks = require('browser_bookmarks')
  browser_bookmarks.setup({
    selected_browser = 'vivaldi',
  })

  local telescope = require('telescope')
  telescope.load_extension('bookmarks')
  telescope.load_extension('fzy_native')
  telescope.load_extension('zoxide')

  local actions = require('telescope.actions')
  telescope.setup({
    defaults = {
      mappings = {
        i = {
          ['<Esc>'] = actions.close,

          -- Left results window scrolling (already bound)
          -- <Tab>
          -- <S-Tab>

          -- Right preview window scrolling
          ['<F14>'] = actions.preview_scrolling_up, -- Wezterm sends this for CMD+u
          ['<F13>'] = actions.preview_scrolling_down, -- Wezterm sends this for CMD+d

          ['<C-q>'] = actions.send_to_qflist,
        },
      },
    },
  })
end

return {
  'nvim-telescope/telescope.nvim',
  opts = function(_, conf)
    local zoxide_utils = require('telescope._extensions.zoxide.utils')
    conf.extensions = {
      fzy_native = {
        override_generic_sorter = true,
        override_file_sorter = true,
      },
      zoxide = {
        ['<CR>'] = { action = zoxide_utils.create_basic_command('split') },
      },
    }
    conf.defaults.file_sorter = require('telescope.sorters').get_fzy_sorter
    return conf
  end,
  config = configure_telescope,
  dependencies = {
    { 'nvim-lua/plenary.nvim' },
    { 'jvgrootveld/telescope-zoxide' },
    { 'nvim-telescope/telescope-fzy-native.nvim' },
    { 'dhruvmanila/telescope-bookmarks.nvim' },
  },
  keys = {
    -- File Finders
    {
      '<LocalLeader>p',
      '<Cmd>lua require("telescope.builtin").oldfiles()<CR>',
      mode = { 'n', 't' },
      desc = 'Find prev open files',
    },
    {
      '<LocalLeader>f',
      '<Cmd>lua require("telescope.builtin").git_files()<CR>',
      mode = { 'n', 't' },
      desc = 'Find by filename',
    },
    {
      '<Leader>fi',
      '<Cmd>lua require("telescope.builtin").git_files()<CR>',
      mode = { 'n', 't' },
      desc = 'Find by filename',
    },
    {
      '<Leader>fia',
      '<Cmd>lua require("telescope.builtin").find_files({cwd="~/code"})<CR>',
      mode = { 'n', 't' },
      desc = 'Find by filename (all repos)',
    },
    -- Grep for text in this Git repo
    {
      '<LocalLeader>g',
      '<Cmd>ProjectRootCD<CR><Bar><Cmd>lua require("telescope.builtin").live_grep()<CR>',
      mode = { 'n', 't' },
      desc = 'Live grep this repo',
    },
    {
      '<Leader>gg',
      '<Cmd>ProjectRootCD<CR><Bar><Cmd>lua require("telescope.builtin").live_grep()<CR>',
      mode = { 'n', 't' },
      desc = 'Live grep this repo',
    },
    {
      '<Leader>gga',
      '<Cmd>cd ~/code<CR><Bar><Cmd>lua require("telescope.builtin").live_grep()<CR>',
      mode = { 'n', 't' },
      desc = 'Live Grep (all repos)',
    },
    {
      '<Leader>vv',
      '<Cmd>lua require("telescope.builtin").grep_string({ cwd = vim.api.nvim_eval("projectroot#get()") })<CR>',
      mode = 'n',
      desc = 'Grep word under cursor',
    },
    -- Buffers
    {
      '<LocalLeader>b',
      '<Cmd>lua require("telescope.builtin").buffers()<CR>',
      mode = { 'n', 't' },
      desc = 'Find by buffer filename',
    },
    {
      '<Leader>b',
      '<Cmd>lua require("telescope.builtin").buffers()<CR>',
      mode = { 'n', 't' },
      desc = 'Find by buffer filename',
    },
    {
      '<Leader>qfh',
      '<Cmd>lua require("telescope.builtin").quickfixhistory()<CR>',
      mode = 'n',
      desc = 'List quickfix history',
    },
    {
      '<Leader>jl',
      '<Cmd>lua require("telescope.builtin").jumplist()<CR>',
      mode = 'n',
      desc = 'List jump list',
    },
    {
      '<Leader>fb',
      '<Cmd>lua require("telescope.builtin").current_buffer_fuzzy_find()<CR>',
      mode = { 'n' },
      desc = 'Find fuzzy in this buffer',
    },
    -- Other Pickers
    {
      '<Leader>fm',
      '<Cmd>lua require("telescope.builtin").man_pages()<CR>',
      mode = { 'n', 't' },
      desc = 'Find man page',
    },
    {
      '<LocalLeader>d',
      '<Cmd>lua require("telescope").extensions.zoxide.list{}<CR>',
      mode = { 'n', 't' },
      desc = 'Open dir',
    },
    {
      '<LocalLeader>k',
      '<Cmd>Telescope bookmarks<CR>',
      mode = { 'n', 't' },
      desc = 'Find Vivaldi bookmark',
    },
    {
      '<Leader>vh',
      '<Cmd>lua require("telescope.builtin").help_tags()<CR>',
      mode = 'n',
      desc = 'Find Vim help tag',
    },
    {
      '<Leader>vm',
      '<Cmd>lua require("telescope.builtin").keymaps()<CR>',
      mode = 'n',
      desc = 'Search Vim keymaps',
    },
    {
      '<Leader>va',
      '<Cmd>lua require("telescope.builtin").autocommands()<CR>',
      mode = 'n',
      desc = 'Search Vim autocommands',
    },
    {
      '<Leader>vc',
      '<Cmd>lua require("telescope.builtin").commands()<CR>',
      mode = 'n',
      desc = 'Search Vim commands',
    },
    {
      '<Leader>vhi',
      '<Cmd>lua require("telescope.builtin").highlights()<CR>',
      mode = 'n',
      desc = 'Search vim highlights',
    },
    -- TODO: Add https://github.com/nvim-telescope/telescope.nvim?tab=readme-ov-file#git-pickers
  },
}
