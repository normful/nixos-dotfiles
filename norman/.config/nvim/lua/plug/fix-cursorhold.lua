local utils = require('utils')

local function configure()
  local g = vim.g
  g.cursorhold_updatetime = 100
end

return {
  -- Non-packer elements
  name = 'antoinemadec/FixCursorHold.nvim',
  configure = configure,
}
