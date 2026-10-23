return {
  'numToStr/Comment.nvim',
  ---@type CommentConfig | {}
  opts = {
    toggler = {
      line = 'tcl',
    },
    opleader = {
      line = 'cl',
      block = 'cb',
    },
    mappings = {
      basic = true,
      extra = false,
    },
  },
  event = 'VeryLazy',
}
