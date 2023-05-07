local function configure_projectionist()
  local g = vim.g
  g.projectionist_heuristics = {
    ['*.go'] = {
      ['*.go'] = { alternate = '{}_test.go', ['type'] = 'source' },
      ['*_test.go'] = { alternate = '{}.go', ['type'] = 'test' },
    },
  }
end

return {
  'tpope/vim-projectionist',
  config = configure_projectionist,
  event = 'VeryLazy',
}
