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
      "<Cmd>lua require('zk').new({ notebook_path = vim.fn.expand('~/code/alcove'), title = vim.fn.input('New note title: ') })<CR>",
      mode = 'n',
      desc = 'New note',
    },

    ----------------------------
    -- Working with other notes
    ----------------------------

    -- See augroups.lua for code of <Leader>zl mapping
    -- This config only is for plugin lazy loading
    { '<Leader>zl', mode = 'n', ft = 'markdown' },
    { '<Leader>zl', mode = 'v', ft = 'markdown' },

    {
      '<Leader>zm',
      ":'<,'>ZkNewFromContentSelection { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('New title (selected contents will be moved in): ') }<CR>",
      mode = 'v',
      buffer = true,
      ft = 'markdown',
      desc = 'Move selected text to new note',
    },

    -- Note: I purposely don't map and use ZkNewFromTitleSelection
    -- Instead, the more sophisticated <CR> MkdnEnter mapping from mkdnflow.nvim does the same thing as ZkNewFromTitleSelection

    ----------------------------
    -- Open existing notes
    ----------------------------

    {
      '<Leader>zo',
      "<Cmd>lua require('zk').edit({ notebook_path = vim.fn.expand('~/code/alcove'), sort = { 'modified' } }, { title = 'Recent notes' })<CR>",
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

    -- These are purposely using the same <Leader>zf, but in different modes
    {
      '<Leader>zf',
      "<Cmd>lua require('zk').edit({ notebook_path = vim.fn.expand('~/code/alcove'), sort = { 'modified' }, match = { vim.fn.input('Search notes containing text: ') } }, { title = 'Search results' })<CR>",
      mode = 'n', -- Normal mode mapping
      desc = 'Search notes containing...',
    },
    {
      '<Leader>zf',
      ":'<,'>ZkMatch({ notebook_path = vim.fn.expand('~/code/alcove') })<CR>",
      mode = 'v', -- Visual mode mapping
      desc = 'Search notes using selection',
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
    {
      '<Leader>zi',
      '<Cmd>ZkIndex<CR>',
      mode = 'n',
      desc = 'Reindex notes',
    },
    {
      '<Leader>zb',
      "<Cmd>ZkBuffers({ notebook_path = vim.fn.expand('~/code/alcove') })<CR>",
      mode = 'n',
      desc = 'Switch to other note buffer',
    },
  },
}
