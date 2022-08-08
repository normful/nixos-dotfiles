local utils = require('utils')

local function configure()
  utils.nnoremap_silent_bulk({
    ['<Leader>bd'] = '<Cmd>Bdelete!<CR>',
  })
end

return {
  name = 'moll/vim-bbye',
  configure = configure,
}
