local function configure_colorizer()
  require('colorizer').setup()
end

return {
  'norcalli/nvim-colorizer.lua',
  config = configure_colorizer,
  event = 'VeryLazy',
}
