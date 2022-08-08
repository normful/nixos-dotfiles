local function configure()
  local g = vim.g

  -- rootmarkers are in descending priority
  g.rootmarkers = {'.nvmrc', 'main.go', '.projectroot', '.git'}
end

return {
  -- Changes cwd to Project Root
  name = 'dbakker/vim-projectroot',
  configure = configure,
}
