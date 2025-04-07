return {
  'nvim-treesitter/nvim-treesitter',
  dependencies = {
    { 'nvim-treesitter/nvim-treesitter-textobjects', event = { 'BufReadPost', 'BufNewFile' } },
    -- NOTE(norman): I'm not using nvim-treesitter/nvim-treesitter-refactor because none of it was useful to me
  },
  keys = {
    { '<F3>', '<Cmd>InspectTree<CR>' },
  },
  opts = function(_, conf)
    local languages_to_ensure_installed = {
      'bash',
      'c',
      'cpp',
      'css',
      'dockerfile',
      'editorconfig',
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
      'graphql',
      'groovy',
      'helm',
      'html',
      'hurl',
      'java',
      'javascript',
      'jsdoc',
      'json',
      'json5',
      'latex',
      'lua',
      'make',
      'markdown_inline',
      'nginx',
      'nix',
      'norg',
      'python',
      'regex',
      'ron',
      'ruby',
      'rust',
      'scss',
      'sql',
      'ssh_config',
      'svelte',
      'terraform',
      'toml',
      'tsx',
      'typescript',
      'typst',
      'vim',
      'yaml',
    }
    for _, lang in ipairs(languages_to_ensure_installed) do
      table.insert(conf.ensure_installed, lang)
    end
    conf.sync_install = false
    conf.auto_install = true
    conf.ignore_install = {}
    conf.indent = { enable = true }
    conf.incremental_selection = {
      enable = true,
      keymaps = {
        -- NOTE(norman): This is very helpful and you should get used to using it more.
        init_selection = '<Space>',
        node_incremental = '<Space>',
        node_decremental = '<BS>',
      },
    }
    conf.highlight.custom_captures = {
      ['property_identifier'] = 'TSProperty', -- Highlight the @property_identifier capture group with the "TSProperty" highlight group
    }

    -- Disable slow treesitter highlight for large files
    conf.highlight.disable = function(lang, buf)
      local max_filesize = 100 * 1024 -- 100 KB
      local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
      if ok and stats and stats.size > max_filesize then
        return true
      end
    end

    conf.textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ['if'] = { query = '@function.inner', desc = 'Inside function' },
          ['af'] = { query = '@function.outer', desc = 'Around function' },

          ['ib'] = { query = '@block.inner', desc = 'Inside block' },
          ['ab'] = { query = '@block.outer', desc = 'Around block' },

          ['ii'] = { query = '@conditional.inner', desc = 'Inside conditional' },
          ['ai'] = { query = '@conditional.outer', desc = 'Around conditional' },

          ['ic'] = { query = '@call.inner', desc = 'Inside call' },
          ['ac'] = { query = '@call.outer', desc = 'Around call' },

          ['i:'] = { query = '@property.inner', desc = 'Inside property' },
          ['a:'] = { query = '@property.outer', desc = 'Around property' },
          [',:'] = { query = '@property.lhs', desc = 'Left of property' },
          ['.:'] = { query = '@property.rhs', desc = 'Right of property' },

          ['ik'] = { query = '@class.inner', desc = 'Inside class' },
          ['ak'] = { query = '@class.outer', desc = 'Around class' },

          --
          ['as'] = { query = '@statement.outer', desc = 'Around statement' },

          --
          ['a/'] = { query = '@comment.outer', desc = 'Around comment' },

          ['is'] = { query = '@scopename.inner', desc = 'Inside scope name' },
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
        enable = true,
        swap_next = {
          ['<Leader>sp'] = '@parameter.inner',
          ['<Leader>sf'] = '@function.outer',
        },
        swap_previous = {
          ['<Leader>sP'] = '@parameter.inner',
          ['<Leader>sF'] = '@function.outer',
        },
      },
    }

    return conf
  end,
}
