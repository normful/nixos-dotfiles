local utils = require('utils')

local function configure()
  local globals = require('globals')
  if not vim.tbl_contains(globals.fts_enabled, 'markdown') then return end

  local g = vim.g
  local set = utils.set
end

return {
  name = 'iamcco/markdown-preview.nvim',
  configure = configure,

  run = 'cd app && yarn install',
  cmd = 'MarkdownPreview',

  ft = utils.enabled_fts({'markdown'}),
}
