local function configure_git_messenger()
  local g = vim.g
  g.git_messenger_include_diff = 'current'
  g.git_messenger_always_into_popup = true
  g.git_messenger_date_format = '%+'
end

return {
  'rhysd/git-messenger.vim',
  config = configure_git_messenger,
  keys = {
    { 'M', '<Cmd>GitMessenger<CR>' },
  },
}
