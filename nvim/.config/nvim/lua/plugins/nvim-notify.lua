local function configure_nvim_notify()
  require('notify').setup({
    stages = 'fade_in_slide_out',
  })
end

return {
  'rcarriga/nvim-notify',
  config = configure_nvim_notify,
  lazy = false,
}
