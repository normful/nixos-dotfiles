local function configure_editorconfig()
  vim.g.EditorConfig_exclude_patterns = { 'fugitive://.*' }
end

return {
  'editorconfig/editorconfig-vim',
  config = configure_editorconfig,
  event = 'VeryLazy',
}
