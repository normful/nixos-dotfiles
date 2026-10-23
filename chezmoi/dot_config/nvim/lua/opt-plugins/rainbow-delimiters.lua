local function configure_rainbow_delimiters()
  local rainbow_delimiters = require('rainbow-delimiters.setup')
  rainbow_delimiters.setup({
    highlight = {
      'RainbowDelimiterViolet',
      'RainbowDelimiterCyan',
      'RainbowDelimiterGreen',
      'RainbowDelimiterBlue',
      'RainbowDelimiterOrange',
      'RainbowDelimiterYellow',
      'RainbowDelimiterRed',
    },
  })
end

return {
  'HiPhish/rainbow-delimiters.nvim',
  event = 'VeryLazy',
  config = configure_rainbow_delimiters,
}
