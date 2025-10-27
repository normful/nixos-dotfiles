local function configure_zk_nvim()
  require('zk').setup({
    picker = 'telescope',
    lsp = {
      auto_attach = { enabled = true, filetypes = { 'markdown' } },
    },
  })
end

return {
  'zk-org/zk-nvim',
  config = configure_zk_nvim,
  lazy = false,
  keys = {
    ----------------------------
    -- Create a new note
    ----------------------------

    {
      '<Leader>zn',
      "<Cmd>ZkNew { title = vim.fn.input('New note title: ') }<CR>",
      mode = 'n',
      desc = 'New note',
    },

    ----------------------------
    -- Working with other notes
    ----------------------------

    -- See contents of <Leader>zl mapping in augroups.lua
    -- This is just for configuring lazy loading of this plugin
    { '<Leader>zl', mode = 'n', ft = 'markdown' },
    { '<Leader>zl', mode = 'v', ft = 'markdown' },

    {
      '<Leader>zm',
      ":'<,'>ZkNewFromContentSelection { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('New title (selected contents will be moved in): ') }<CR>",
      mode = 'v',
      buffer = true,
      ft = 'markdown',
      desc = 'Move selected contents to new note',
    },

    -- Note: I purposely do not have a mapping for ZkNewFromTitleSelection
    -- Instead, the more sophiscticated <CR> MkdnEnter mapping from mkdnflow.nvim does the same thing as ZkNewFromTitleSelection

    ----------------------------
    -- Open existing notes
    ----------------------------

    {
      '<Leader>zo',
      "<Cmd>ZkNotes { sort = { 'modified' } }<CR>",
      mode = 'n',
      desc = 'Open notes',
    },
    {
      '<Leader>zt',
      '<Cmd>ZkTags<CR>',
      mode = 'n',
      desc = 'Open notes by tags',
    },

    ----------------------------
    -- Search existing notes
    ----------------------------

    {
      '<Leader>zf',
      "<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>",
      mode = 'n',
      desc = 'Search notes',
    },
    {
      '<Leader>zf',
      ":'<,'>ZkMatch<CR>",
      mode = 'v',
      desc = 'Search notes using visual selection',
    },

    ----------------------------
    -- Other commands
    ----------------------------

    {
      '<Leader>zd',
      '<Cmd>ZkLinks<CR>',
      mode = 'n',
      buffer = true,
      ft = 'markdown',
      desc = 'Forward links',
    },
    {
      '<Leader>za',
      '<Cmd>ZkBacklinks<CR>',
      mode = 'n',
      buffer = true,
      ft = 'markdown',
      desc = 'Backward links',
    },

    {
      'K',
      '<Cmd>lua vim.lsp.buf.hover()<CR>',
      mode = 'n',
      buffer = true,
      ft = 'markdown',
      desc = 'Preview linked note',
    },
  },
}
