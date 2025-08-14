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
      'php',
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

    local MAX_LINE_LENGTH = 200 -- Lines longer than this will trigger disabling
    local MAX_CHECK_LINES = 500 -- Check only the first N lines for performance
    local MAX_FILE_SIZE_MB = 1 -- Disable entirely for files larger than this (in MB)

    -- The function that decides whether to disable Treesitter for a buffer
    local function should_disable_treesitter(lang, bufnr)
      local file_name = vim.api.nvim_buf_get_name(bufnr)

      -- unnamed/temporary buffers
      if file_name == '' or file_name == nil then
        return false
      end

      if string.sub(file_name, -7) == '.min.js' then
        vim.schedule(function()
          vim.notify('Treesitter disabled for minified JS file', vim.log.levels.WARN, { title = 'Treesitter Performance' })
        end)
        return true
      end

      local file_size_limit_bytes = MAX_FILE_SIZE_MB * 1024 * 1024
      local ok, stat = pcall(vim.loop.fs_stat, file_name)
      if ok and stat and stat.size > file_size_limit_bytes then
        vim.schedule(function()
          vim.notify(
            string.format('Treesitter disabled for large file (> %d MB)', MAX_FILE_SIZE_MB),
            vim.log.levels.WARN,
            { title = 'Treesitter Performance' }
          )
        end)
        return true
      end

      local line_count = vim.api.nvim_buf_line_count(bufnr)
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, math.min(MAX_CHECK_LINES, line_count), false)

      -- Loop through the lines (won't run if lines table is empty)
      for i, line in ipairs(lines) do
        if #line > MAX_LINE_LENGTH then
          -- Found a long line, notify and disable
          vim.schedule(function()
            vim.notify(
              string.format('Treesitter disabled (line %d > %d chars)', i, MAX_LINE_LENGTH),
              vim.log.levels.WARN,
              { title = 'Treesitter Performance' }
            )
          end)
          return true
        end
      end

      -- If none of the above disabling conditions were met, allow Treesitter
      return false
    end

    conf.highlight.disable = should_disable_treesitter

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
