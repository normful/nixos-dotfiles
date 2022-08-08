local function configure()
  local g = vim.g
  local utils = require('utils')

  g.git_messenger_include_diff = 'current'
  g.git_messenger_always_into_popup = true
  g.git_messenger_date_format = '%+'

  -- utils.nnoremap_silent_bulk({
  --   ['M'] = '<Cmd>GitMessenger<CR>',
  -- })
end

return {
  name = 'rhysd/git-messenger.vim',
  configure = configure,
}
