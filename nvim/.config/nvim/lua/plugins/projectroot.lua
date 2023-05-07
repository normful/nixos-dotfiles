local function configure_projectroot()
  local g = vim.g

  -- rootmarkers are in descending priority
  g.rootmarkers = { '.nvmrc', 'main.go', '.projectroot', '.git' }
end

return {
  'dbakker/vim-projectroot',
  config = configure_projectroot,
  event = 'VeryLazy',
}
