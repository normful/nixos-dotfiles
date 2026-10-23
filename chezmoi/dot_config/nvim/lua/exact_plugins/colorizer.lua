local function configure_colorizer()
  require('colorizer').setup({
    '*',
    css = {
      RRGGBBAA = true, -- #RRGGBBAA hex codes
      rgb_fn = true, -- CSS rgb() and rgba() functions
      hsl_fn = true, -- CSS hsl() and hsla() functions
      css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
      css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
      tailwind = true,
    },
    markdown = {
      rgb_fn = false,
      names = true,
    },
  })
end

return {
  'normful/nvim-colorizer.lua',
  config = configure_colorizer,
  event = 'VeryLazy',
}
