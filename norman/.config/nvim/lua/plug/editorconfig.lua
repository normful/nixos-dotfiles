local function configure()
  vim.g.EditorConfig_exclude_patterns = {'fugitive://.*'}
end

return {
  name = 'editorconfig/editorconfig-vim',
  configure = configure,
}
