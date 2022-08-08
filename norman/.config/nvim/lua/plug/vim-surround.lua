local utils = require('utils')

local function configure()
  local globals = require('globals')

  local g = vim.g
  g.surround_no_mappings = true
  g.surround_no_insert_mappings = true

  utils.nmap_silent_bulk({
    ['yss'] = '<Plug>Yssurround',
    ['ys'] = '<Plug>Ysurround',
  })
end

return {
  name = 'tpope/vim-surround',
  configure = configure,
}
