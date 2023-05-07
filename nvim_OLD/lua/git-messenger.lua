local function configure_git_messenger()
  local g = vim.g

  g.git_messenger_include_diff = 'current'
  g.git_messenger_always_into_popup = true
  g.git_messenger_date_format = '%+'

  -- utils.nnoremap_silent_bulk({
  --   ['M'] = '<Cmd>GitMessenger<CR>',
  -- })
end

configure_git_messenger()
