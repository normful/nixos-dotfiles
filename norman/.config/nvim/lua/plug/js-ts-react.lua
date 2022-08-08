local function configure()
  local globals = require('globals')
  local utils = require('utils')

  if not vim.tbl_contains(globals.fts_enabled, 'javascript') then return end
  if not vim.tbl_contains(globals.fts_enabled, 'javascriptreact') then return end
  if not vim.tbl_contains(globals.fts_enabled, 'typescript') then return end
  if not vim.tbl_contains(globals.fts_enabled, 'typescriptreact') then return end

  local filetypes = 'javascript,javascriptreact,typescript,typescriptreact'
  utils.create_augroups({
    js_ts_react_augroup = {
      {'FileType', filetypes, 'Coverage'},
      {'FileType', filetypes, [[nnoremap <buffer> <Leader>cov :AsyncRun -cwd=<root> -silent node_modules/.bin/jest --coverage %:p<CR>]]},
    },
  })
end

return {
  name = 'JavaScript, TypeScript, React',
  configure = configure,
  not_plugin = true,
}
