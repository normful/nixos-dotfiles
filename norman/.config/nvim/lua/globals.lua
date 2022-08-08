local globals = {}
local home = os.getenv("HOME")

function globals:load_variables()
  self.home = home

  -- Expanded: ~/.cache/nvim
  local cache_dir = home .. '/.cache/nvim'
  self.cache_dir = cache_dir

  -- Expanded: ~/.cache/nvim/backup
  self.backup_dir = cache_dir .. '/backup'

  -- Expanded: ~/.cache/nvim/swap
  self.swap_dir = cache_dir .. '/swap'

  -- Expanded: ~/.cache/nvim/undo
  self.undo_dir = cache_dir .. '/undo'

  -- Expanded: ~/.cache/nvim/session
  self.session_dir = cache_dir .. '/session'

  -- Expanded: ~/.cache/nvim/tags
  self.tags_dir = cache_dir .. '/tags'

  self.cache_subdirs = {
	  self.backup_dir,
	  self.swap_dir,
	  self.undo_dir,
	  self.session_dir,
	  self.tags_dir,
  }

  -- Expanded: ~/.local/share/nvim/site (usually)
  local data_dir = vim.fn.stdpath('data') .. '/site'
  self.data_dir = data_dir

  -- Expanded: ~/.local/share/nvim/site/pack/packer
  self.packer_plugins_dir = data_dir .. '/pack/packer'

  -- Expanded: ~/.config/nvim (usually)
  local config_dir = vim.fn.stdpath('config')

  self.main_lua    = config_dir .. '/lua/main.lua'
  self.plugins_lua = config_dir .. '/lua/plugins.lua'
  self.plug_dir    = config_dir .. '/lua/plug'

  --[[
    Filetypes to enable plugins for.

    Comment out any of the languages you're not using for long periods of time,
    to avoid unnecessary loading and configuration.

    IMPORTANT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    Run :PackerSync after updating this list table.
    IMPORTANT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  --]]
  self.fts_enabled = {
    'Jenkinsfile',
    -- 'apparmor',
    'coffee',
    'confluencewiki',
    'css',
    'eco',
    'go',
    -- 'graphql',
    'helm',
    'javascript',
    'javascriptreact',
    'jinja',
    'json',
    'json5',
    'log',
    'markdown',
    'mustache',
    'plantuml',
    -- 'pug',
    'puml',
    'python',
    'ruby',
    'scss',
    -- 'thrift',
    'text',
    'txt',
    'typescript',
    'typescriptreact',
    'yaml',
  }
  --[[
    IMPORTANT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    Run :PackerSync after updating this list table.
    IMPORTANT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  --]]
end

globals:load_variables()

return globals
