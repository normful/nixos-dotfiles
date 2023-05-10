local function configure_neorg()
  require('neorg').setup({
    load = {
      ['core.defaults'] = {},
      ['core.keybinds'] = {
        config = {
          default_keybinds = true,
          neorg_leader = '<Leader>o',
        },
      },
      ['core.concealer'] = {
        config = {
          folds = false,
          icon_preset = 'diamond',
          icons = {
            todo = {
              undone = { icon = ' ' },
              done = { icon = '✔' },
              uncertain = { icon = '?' },
              urgent = { icon = '!' },

              cancelled = { icon = '_' },
              on_hold = { icon = '=' },
              pending = { icon = '-' },
            },
          }
        },
      },
      ['core.manoeuvre'] = {},
      ['core.journal'] = {
        config = {
          strategy = 'flat',
          journal_folder = 'journal',
          use_template = false,
          workspace = 'notes',
          open_last_workspace = true,
          use_popup = true,
        }
      },
      ['core.dirman'] = {
        config = {
          workspaces = {
            notes = '~/code/notes',
          },
          default_workspace = 'notes',
          autochdir = true,
          index = 'index.norg',
        },
      },
      ['core.completion'] = {
        config = {
          engine = 'nvim-cmp',
        },
      },
      ['core.presenter'] = {
        config = {
          zen_mode = 'truezen',
        },
      },
      ['core.esupports.metagen'] = {
        config = {
          -- One of "none", "auto" or "empty"
          -- - "none" generates no metadata
          -- - "auto" generates metadata if it is not present
          -- - "empty" generates metadata only for new files/buffers.
          type = 'empty',

          -- Whether updated date field should be automatically updated on save if required
          update_date = false,

          -- How to generate a tabulation inside the `@document.meta` tag
          tab = '',

          -- Custom delimiter between tag and value
          delimiter = ': ',

          -- Custom template to use for generating content inside `@document.meta` tag
          template = {
            {
              'title',
              function()
                return vim.fn.expand('%:p:t:r')
              end,
            },

            {
              'date',
              function()
                return os.date('%Y-%m-%d')
              end,
            },

            { '[taxonomies]', '' },
            { 'tags', '[]' },
          },

        },
      },
      ['core.summary'] = {
        config = {
          strategy = 'metadata',
        },
      },
      ['core.export'] = {
        config = {},
      },
      ['core.export.markdown'] = {
        config = {
          extensions = 'all',
          metadata = {
            ['start'] = '+++',
            ['end'] = '+++',
          },
        },
      },
    },
  })
end

return {
  'nvim-neorg/neorg',
  dependencies = {
    { 'nvim-lua/plenary.nvim' },
    { 'Pocco81/true-zen.nvim' },
  },
  keys = {
    { '<Leader>ni', '<Cmd>Neorg index<CR>' },
    { '<Leader>ei', '<Cmd>Neorg index<CR>' },
    { '<Leader>en', '<Cmd>Neorg journal today<CR>' },
    { '<Leader>er', '<Cmd>Neorg return<CR>' },

    { '<Leader>nc', '<Cmd>Neorg toggle-concealer<CR>' },

    { '<Leader>mb',
      function()
        local markdown_file = '/Users/norman/code/blog/content/blog/' .. string.format('%s.md', vim.fn.expand('%:t:r'))
        vim.cmd(':Neorg export to-file ' .. markdown_file)

        vim.cmd('vsplit')
        local win = vim.api.nvim_get_current_win()
        local buf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_win_set_buf(win, buf)

        vim.cmd('e ' .. markdown_file)

        -- TODO(norman): Figure out how to automatically tweak the exported
        -- meta block in the markdown_file so that it is in the format that
        -- works with your Zola theme.
      end,
      desc = 'Export to markdown blog file, edit markdown',
    },
  },
  config = configure_neorg,
  lazy = false,
  build = ':Neorg sync-parsers',
}
