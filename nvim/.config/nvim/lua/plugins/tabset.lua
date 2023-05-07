local function configure_tabset()
  local tabset = require('tabset')
  tabset.setup({
    defaults = {
      tabwidth = 2,
      expandtab = true,
    },
    languages = {
      {
        filetypes = {
          'markdown',
          'gitconfig',
          'vim',
        },
        config = {
          tabwidth = 4,
          expandtab = true,
        },
      },
    },
  })
end

return {
  'FotiadisM/tabset.nvim',
  config = configure_tabset,
  lazy = false,
}
