local function configure_treesitter()
  local utils = require('utils')

  require('nvim-treesitter.configs').setup({
    auto_install = true,
    ensure_installed = {
      'bash',
      'css',
      'dockerfile',
      'fish',
      'git_rebase',
      'gitattributes',
      'gitcommit',
      'gitignore',
      'go',
      'gomod',
      'gosum',
      'html',
      'java',
      'javascript',
      'json',
      'lua',
      'markdown',
      'python',
      'regex',
      'scss',
      'toml',
      'tsx',
      'typescript',
      'vim',
      'yaml',
    },
    highlight = {
      enable = true,
      custom_captures = {
        -- Not sure if this is needed or not...
        ['property_identifier'] = 'TSProperty',
      },
    },
    indent = {
      enable = true,
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        -- NOTE(norman): This is very helpful and you should get used to using it more.
        init_selection = '<Space>',
        node_incremental = '<Space>',
        node_decremental = '<BS>',

        scope_incremental = 'grc',
      },
    },
    playground = {
      enable = true,
      updatetime = 25,
      persist_queries = false,
      keybindings = {
        toggle_query_editor = 'o',

        toggle_hl_groups = 'i',
        toggle_injected_languages = 't',
        toggle_anonymous_nodes = 'a',
        toggle_language_display = 'I',

        focus_language = 'f',
        unfocus_language = 'F',

        update = 'R',
        goto_node = '<CR>',

        show_help = '?',
      },
    },
    textsubjects = {
      enable = true,
      keymaps = {
        ['v'] = 'textsubjects-smart',
      }
    },
    -- https://github.com/HiPhish/nvim-ts-rainbow2
    rainbow = {
      enable = true,
    },
  })
end

return {
  'nvim-treesitter/nvim-treesitter',
  dependencies = {
    { 'nvim-treesitter/playground', event = 'VeryLazy' },
    { 'nvim-treesitter/nvim-treesitter-textobjects', event = 'VeryLazy' },
    { 'HiPhish/nvim-ts-rainbow2', event = 'VeryLazy' },

    -- NOTE(norman): I'm purposely not using nvim-treesitter/nvim-treesitter-refactor because none of it was useful to me
  },
  keys = {
    { '<F3>', '<Cmd>TSPlaygroundToggle>CR>' },
    { 'L', '<Cmd>TSNodeUnderCursor>CR>' },
  },
  config = configure_treesitter,
  event = 'VeryLazy',
}
