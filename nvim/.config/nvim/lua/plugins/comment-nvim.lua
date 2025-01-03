local function configure_comment_nvim()
  require('Comment').setup({
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
  })
end

return {
  'numToStr/Comment.nvim',
  config = configure_comment_nvim,
  event = 'VeryLazy',
}
