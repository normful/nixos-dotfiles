local function configure_nvim_notify()
  vim.notify = require('notify')
end

return {
  'rcarriga/nvim-notify',
  config = configure_nvim_notify,
  lazy = false,
}
