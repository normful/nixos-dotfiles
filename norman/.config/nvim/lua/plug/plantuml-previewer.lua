local utils = require('utils')

local function configure()
  local globals = require('globals')
  if not vim.tbl_contains(globals.fts_enabled, 'plantuml') then return end

  vim.g['plantuml_previewer#plantuml_jar_path'] = globals.home..'/bin/plantuml.jar'
  vim.g['plantuml_previewer#save_format'] = 'png'

  utils.create_augroups({
    plantuml_previewer_augroup = {
      {'BufWritePost', '*.plantuml,*.puml', ':PlantumlSave'},
    },
  })

end

return {
  name = 'weirongxu/plantuml-previewer.vim',
  configure = configure,
  ft = { 'plantuml', 'puml' },
}
