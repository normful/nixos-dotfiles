local function configure_treesitter()
  local configs = require('nvim-treesitter.configs')
  configs.setup({
    -- -----------------------------------------------
    -- START OF nvim-treesitter/nvim-treesitter config
    -- -----------------------------------------------
    ensure_installed = {
      'bash',
      'css',
      'dockerfile',
      'erlang',
      'fish',
      'git_config',
      'git_rebase',
      'git_rebase',
      'gitattributes',
      'gitcommit',
      'gitignore',
      'gleam',
      'go',
      'gomod',
      'gosum',
      'gotmpl',
      'html',
      'java',
      'javascript',
      'jsdoc',
      'json',
      'json5',
      'lua',
      'make',
      'markdown',
      'nix',
      'norg',
      'python',
      'regex',
      'scss',
      'sql',
      'svelte',
      'terraform',
      'toml',
      'tsx',
      'typescript',
      'vim',
      'yaml',
    },
    sync_install = false,
    auto_install = true,
    ignore_install = {},
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

        -- scope_incremental = 'grc', -- I haven't used this one yet
      },
    },
    modules = {},
    highlight = {
      enable = true,
      custom_captures = {
        ['property_identifier'] = 'TSProperty', -- Highlight the @property_identifier capture group with the "TSProperty" highlight group
      }
    },
    -- -----------------------------------------------
    -- END OF nvim-treesitter/nvim-treesitter config
    -- -----------------------------------------------

    -- textsubjects is config for https://github.com/nvim-treesitter/nvim-treesitter-textobjects
    textsubjects = {
      enable = true,
      keymaps = {
        ['v'] = 'textsubjects-smart',
      },
    },
  })
end

return {
  'nvim-treesitter/nvim-treesitter',
  dependencies = {
    { 'nvim-treesitter/nvim-treesitter-textobjects', event = 'VeryLazy' },

    -- NOTE(norman): I'm purposely not using nvim-treesitter/nvim-treesitter-refactor because none of it was useful to me
  },
  keys = {
    { '<F3>', '<Cmd>InspectTree<CR>' },
  },
  build = ":TSUpdate",
  config = configure_treesitter,
  lazy = false,
  priority = 100,
}
