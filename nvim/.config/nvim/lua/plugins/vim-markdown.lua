local function configure_vim_markdown()
  local g = vim.g
  g.vim_markdown_auto_insert_bullets = 0
  g.vim_markdown_new_list_item_ident = 0
end

return {
  'preservim/vim-markdown',
  config = configure_vim_markdown,
  ft = 'markdown',
}
