local function configure()
  local g = vim.g

  g.asyncrun_open = 20
  g.asyncrun_status = ''
end

return {
  name = 'skywind3000/asyncrun.vim',
  configure = configure,
}
