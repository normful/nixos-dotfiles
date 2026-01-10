-- IMPORTANT: If you change this file, remember to rebuild the Nix system

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not vim.uv.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = ','
vim.g.maplocalleader = '\\'

local lazy_config = require('lazy-config')

vim.g.base46_cache = vim.fn.stdpath('data') .. '/base46/'

require('lazy').setup({
  {
    'NvChad/NvChad',
    lazy = false,
    branch = 'v2.5',
    import = 'nvchad.plugins',
  },

  { import = 'plugins' },
}, lazy_config)

dofile(vim.g.base46_cache .. 'defaults')
dofile(vim.g.base46_cache .. 'statusline')

require('options')
require('nvchad.autocmds')
require('augroups')

vim.schedule(function()
  require('mappings')
  require('user-commands')
  if vim.g.neovide then
    require('neovide')
  end

  local is_opened_to_dir = vim.fn.isdirectory(vim.v.argv[3]) == 1

  -- Watch directory for changes if started as `nvim <some_dir>`
  if is_opened_to_dir then
    vim.api.nvim_set_current_dir(vim.v.argv[3])
    require('hotreload')
    require('directory-watcher').setup({
      path = vim.fn.getcwd(),
      debounce = 100,
    })
  end
end)
