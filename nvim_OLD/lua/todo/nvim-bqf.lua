local utils = require('utils')

local function configure()
  local bqf = require('bqf')

  bqf.setup({
    auto_enable = true,
    auto_resize_height = false,
  })
end

return {
  name = 'kevinhwang91/nvim-bqf',
  configure = configure,
}
