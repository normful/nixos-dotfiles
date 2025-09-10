return {
  'dhruvasagar/vim-zoom',
  event = 'VeryLazy',
  keys = {
    {
      '<Leader>on',
      ':call zoom#toggle()<CR>',
      desc = 'Toggle window zoom',
    },
  },
}
