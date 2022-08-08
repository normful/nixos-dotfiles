local utils = require('utils')

local function configure()
  vim.g.vimspector_enable_mappings = 'HUMAN'

  -- :VimspectorInstall is needed to update "gadgets" aka "adapters"
  -- :VimspectorUpdate has to be ran occasionally to update them
end

return {
  name = 'puremourning/vimspector',
  configure = configure,
  ft = utils.enabled_fts({ 'go', 'javascript', 'typescript' }),
}
