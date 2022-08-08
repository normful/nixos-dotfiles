local globals = require('globals')
local utils = require('utils')

local print_long_log_lines = false

local function ensure_cache_dirs()
  local cache_dir = globals.cache_dir
  if vim.fn.isdirectory(cache_dir) == 0 then
    os.execute('mkdir -p ' .. cache_dir)
    for _, subdir in pairs(globals.cache_subdirs) do
      if vim.fn.isdirectory(subdir) == 0 then
        os.execute('mkdir -p ' .. subdir)
      end
    end
  end
end

local function ensure_packer()
  -- Expanded: ~/.local/share/nvim/site/pack/packer/opt/packer.nvim
  local dst = globals.packer_plugins_dir .. '/opt/packer.nvim'

  if vim.fn.empty(vim.fn.glob(dst)) > 0 then
    vim.api.nvim_command('!git clone --depth=1 https://github.com/wbthomason/packer.nvim ' .. dst)
  end

  vim.cmd('packadd packer.nvim')
end


local function add_packer_cmds()
  -- Install the specified plugins if they are not already installed
  vim.cmd 'command! PackerInstall lua require("plugins").run("install")'
  vim.cmd 'command! PI            lua require("plugins").run("install")'

  -- Update the specified plugins, installing any that are missing
  vim.cmd 'command! PackerUpdate  lua require("plugins").run("update")'
  vim.cmd 'command! PU            lua require("plugins").run("update")'

  -- Compile lazy-loader code and save to path.
  vim.cmd 'command! PackerCompile lua require("plugins").run("compile")'

  -- Perform a clean followed by an update
  vim.cmd 'command! PackerSync    lua require("plugins").run("sync")'
  vim.cmd 'command! PS            lua require("plugins").run("sync")'

  -- Remove any disabled or no longer managed plugins
  vim.cmd 'command! PackerClean   lua require("plugins").run("clean")'
  vim.cmd 'command! PC            lua require("plugins").run("clean")'
end

local function add_packer_autocmds()
  local install_and_compile_lazy_loading_code =
  utils.create_augroups({
    main_packer_augroup = {
      {'BufWritePost', globals.plugins_lua,          ':PackerCompile'},
      {'BufWritePost', globals.plug_dir .. '/*.lua', ':PackerCompile'},
    },
  })
end

-- Dynamically loads all lua modules in ./plug
-- and executes their `configure` function.
-- Skips modules with `disable == true`.
local function reload_modules_configs()
  local loaded_module_names = {}

  local ok, scandir = pcall(function ()
    return require('plenary.scandir')
  end)
  if not ok then return end

  local module_relpaths = scandir.scan_dir(globals.plug_dir)
  for _, module_relpath in pairs(module_relpaths) do
    local module = dofile(module_relpath)

    if not module.disable then
      module.configure()
      table.insert(loaded_module_names, module.name)
    end
  end

  if print_long_log_lines then
    print('Reloaded non-packer config for all plugins: ' .. table.concat(loaded_module_names, ', '))
  end
end

local function main()
  require('general_settings')

  vim.cmd('silent! colorscheme monokai')

  ensure_cache_dirs()

  ensure_packer()
  add_packer_cmds()

  add_packer_autocmds()

  require('general_maps')
  require('general_commands')
  require('general_augroups')

  local ok, err = pcall(reload_modules_configs)
  if not ok then print('Reloading non-packer config for all plugins failed: ' .. err) end
end

main()
