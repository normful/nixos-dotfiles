return {
  'FotiadisM/tabset.nvim',
  opts = {
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
  },
  event = 'VeryLazy',
}
