local utils = require('utils')

local function configure()
  local toggleWindowZoomRHS = ':call zoom#toggle()<CR>'

  utils.nnoremap_silent_bulk({
    ['<Leader>on'] = toggleWindowZoomRHS,
  })

  -- Override default :on aka :only to also do the same:
  vim.cmd('command! MyOnly ' .. toggleWindowZoomRHS)
end

return {
  name = 'dhruvasagar/vim-zoom',
  configure = configure,
}
