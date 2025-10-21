local function configure_zk_nvim()
  require('zk').setup()
end

return {
  'zk-org/zk-nvim',
  event = 'VeryLazy',
  config = configure_zk_nvim,
}
