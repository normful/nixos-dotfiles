local utils = require('utils')

local function configure()
  local g = vim.g

  g.bexec_splitdir = 'ver'
  g.bexec_filter_types = {
    javascript = 'babel-node',
  }

  utils.nnoremap_silent_bulk({
    ['<Leader>xb'] = '<Cmd>Bexec()<CR>',
  })

  utils.xnoremap_silent_bulk({
    ['<Leader>xb'] = '<Cmd>BexecVisual()<CR>',
  })
end

return {
  name = 'fboender/bexec',
  configure = configure,
  ft = utils.enabled_fts({ 'go', 'ruby', 'javascript', 'typescript' }),
}
