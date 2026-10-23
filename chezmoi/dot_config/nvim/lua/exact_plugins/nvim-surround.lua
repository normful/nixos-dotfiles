local function configure_nvim_surround()
  require('nvim-surround').setup()
end

return {
  'kylechui/nvim-surround',
  config = configure_nvim_surround,
  event = 'VeryLazy',
}
