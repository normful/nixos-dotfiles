local function configure_neorg()
  require('neorg').setup({
    load = {
      ['core.defaults'] = {},
      ['core.dirman'] = {
        config = {
          default_workspace = 'notes',
          index = 'Notes index.norg',
          open_last_workspace = false,
          workspaces = {
            notes = '~/code/notes',
          },
        },
      },
      ['core.journal'] = {
        config = {
          journal_folder = '',
          strategy = 'flat',
          use_template = false,
          workspace = 'notes',
        },
      },
      ['core.concealer'] = {
        config = {
          icon_preset = 'basic',
        },
      },
      ['core.esupports.metagen'] = {
        config = {
          type = 'empty',
          template = {
            {
              'title',
              function()
                return string.format('"%s"', vim.fn.expand('%:p:t:r'))
              end,
            },
            {
              'date',
              function()
                return os.date('%Y-%m-%d')
              end,
            },
          },
          update_date = false,
        },
      },
      ['core.summary'] = {},

      --[[
      -- TODO(norman): Re-enable these export modules and make sure they work as you expect for blogging.
      -- TODO(norman): Add other modules in https://github.com/nvim-neorg/neorg/wiki#other-modules
      -- TODO(norman): Re-enable ./__neorg-old.lua.txt and apply your commits from your previous fork of neorg onto the latest neorg
      --
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
      --]]
    },
  })
end

return {
  'nvim-neorg/neorg',
  config = configure_neorg,
  lazy = false,
}
