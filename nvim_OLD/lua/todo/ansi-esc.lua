local function configure()
  local utils = require('utils')
  utils.nnoremap_silent_bulk({
    ['<LocalLeader>a'] = '<Cmd>AnsiEsc<CR>',
  })
end

return {
  name = 'powerman/vim-plugin-AnsiEsc',
  configure = configure,
}
