return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  ---@type wk.Opts
  opts = {
    preset = 'helix',
    expand = 10,
    win = {
      title = false,
    },
  },
  keys = { '<Localleader>' },
}
