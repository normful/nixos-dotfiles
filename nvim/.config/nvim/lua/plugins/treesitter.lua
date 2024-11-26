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

    textobjects = {

      -- If you want to repeat some of these, consider using https://github.com/ghostbuster91/nvim-next

      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ["if"] = { query = "@function.inner", desc = "Inside function" },
          ["af"] = { query = "@function.outer", desc = "Around function" },

          ["ib"] = { query = "@block.inner", desc = "Inside block" },
          ["ab"] = { query = "@block.outer", desc = "Around block" },

          ["ii"] = { query = "@conditional.inner", desc = "Inside conditional" },
          ["ai"] = { query = "@conditional.outer", desc = "Around conditional" },

          ["ic"] = { query = "@call.inner", desc = "Inside call" },
          ["ac"] = { query = "@call.outer", desc = "Around call" },

          ["i:"] = { query = "@property.inner", desc = "Inside property" },
          ["a:"] = { query = "@property.outer", desc = "Around property" },
          [",:"] = { query = "@property.lhs",   desc = "Left of property" },
          [".:"] = { query = "@property.rhs",   desc = "Right of property" },

          ["ik"] = { query = "@class.inner", desc = "Inside class" },
          ["ak"] = { query = "@class.outer", desc = "Around class" },

          --
          ["as"] = { query = "@statement.outer", desc = "Around statement" },

          --
          ["a/"] = { query = "@comment.outer", desc = "Around comment" },

          ["is"] = { query = "@scopename.inner", desc = "Inside scope name" },
          --
        },
        selection_modes = {
          ['@parameter.outer'] = 'v', -- charwise
          ['@function.outer'] = 'V', -- linewise
          ['@class.outer'] = '<c-v>', -- blockwise
        },
        include_surrounding_whitespace = false,
      },
      swap = {
        enable = false,
        -- Not sure why these are not working...
        -- so I'm disabling for now
        swap_next = {
          ["<Leader>p]"] = "@parameter.inner",
          ["<Leader>wf"] = "@function.outer",
        },
        swap_previous = {
          ["<Leader>p["] = "@parameter.inner",
          ["<Leader>wr"] = "@function.outer",
        },
      },
    }
  })
end

return {
  'nvim-treesitter/nvim-treesitter',
  dependencies = {
    {
      'nvim-treesitter/nvim-treesitter-textobjects',
      lazy = false,
    },

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
