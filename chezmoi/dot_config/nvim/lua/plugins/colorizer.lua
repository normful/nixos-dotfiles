local function configure_colorizer()
  require('colorizer').setup({
    '*',
    markdown = {
      rgb_fn = false,
      names = true,
    },
  })
end

return {
  'norcalli/nvim-colorizer.lua',
  config = configure_colorizer,
  event = 'VeryLazy',
}
