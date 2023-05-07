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
              cancelled = { icon = '₵' },
              on_hold = { icon = 'ℍ' },
              pending = { icon = 'ℙ' },
              uncertain = { icon = '⛏' },
              undone = { icon = ' ' },
              done = { icon = '✔' },
              urgent = { icon = '⁕' },
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
          type = 'auto',

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
    { '<Leader>mb',
      function()
        vim.cmd(':Neorg inject-metadata')

        local markdown_file = '/Users/norman/code/blog/content/blog/' .. string.format('%s.md', vim.fn.expand('%:t:r'))
        vim.cmd(':Neorg export to-file ' .. markdown_file)

        vim.cmd('vsplit')
        local win = vim.api.nvim_get_current_win()
        local buf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_win_set_buf(win, buf)

        vim.cmd('e ' .. markdown_file)
      end,
      desc = 'Inject norg metadata, export to markdown blog post, edit markdown',
    },
    { '<Leader>en', '<Cmd>Neorg journal today<CR>' },
    { '<Leader>er', '<Cmd>Neorg return<CR>' },
  },
  config = configure_neorg,
  lazy = false,
  build = ':Neorg sync-parsers',
}
