local globals = require('globals')
local utils = require('utils')

local packer = nil

-- table for forming all configuration to a single `packer.use()` call
local packer_use_specs = {}

local function packer_setup()
  if packer then
    return
  end
  packer = require('packer')
  packer.init({
    disable_commands = true,
    auto_clean = false,
    display = {
      non_interactive = false,
    },
  })
  packer.reset()
end

local function add_packer_spec(plugin_name, opts)
  table.insert(
    packer_use_specs,
    vim.tbl_extend('error', { plugin_name }, opts)
  )
end

local function necessary(plugin_name, opts)
  add_packer_spec(
    plugin_name,
    vim.tbl_extend('error', { opt = false }, opts or {})
  )
end

local nec = necessary -- alias

local function lazy(plugin_name, opts)
  add_packer_spec(
    plugin_name,
    vim.tbl_extend('error', { opt = true }, opts or {})
  )
end

local function reload_plugins_packer_config()
  -- This will throw an error, if this is the first time this file is loaded
  -- and plugins have not been installed by packer yet.
  -- The workaround is to just restart nvim a few times, when using a new computer.
  local scandir = require('plenary.scandir')

  local module_relpaths = scandir.scan_dir(globals.plug_dir)

  local non_packer_module_fields = { 'name', 'configure', 'funcs', 'not_plugin' }

  for _, module_relpath in pairs(module_relpaths) do
    local module = dofile(module_relpath)
    if not module.disable and not module.not_plugin then
      local opts = vim.deepcopy(module)

      -- Remove non-packer fields from table
      for _, field in pairs(non_packer_module_fields) do
        opts[field] = nil
      end

      add_packer_spec(module.name, opts)
    end

    if module.disable and not module.template then
      print('WARNING: Plugin ' .. module.name .. ' is configured as disabled')
    end
  end
end

-- Only include one-line plugin installations here.
-- If the plugin requires more than one line of configuration, create a module in the `plug` subdir.
-- I don't like having an entire additional file just to specify that a
-- plugin should be installed; just adding one line here is sufficient.
local function packer_use()
  packer_use_specs = {}

  lazy 'wbthomason/packer.nvim'

  -----------------------------------------
  -- NECESSARY PLUGINS
  -----------------------------------------

  nec 'nvim-lua/plenary.nvim'

  -- Color Schemes
  -- nec 'ray-x/aurora'
  -- nec 'novakne/kosmikoa.nvim'
  -- nec 'christianchiarulli/nvcode-color-schemes.vim'
  nec 'normful/monokai.nvim'

  -- Enhanced . repeat
  nec 'tpope/vim-repeat'

  -- Git
  nec 'tpope/vim-fugitive'

  -- Cursor line and cursor column
  nec 'inkarkat/vim-CursorLineCurrentWindow'

  -- Automatically inserts ends like `endif` and `endfunction`
  nec 'tpope/vim-endwise'

  -- Language-specific matching text (extends %)
  nec 'andymass/vim-matchup'

  -- Diff two ranges of lines
  nec 'AndrewRadev/linediff.vim'

  -- Substitution and Typo Correction
  nec 'tpope/vim-abolish'

  -- Automatically causes vim to reload files which have been written on disk
  -- but not modified in the buffer since the last write from vim.
  -- It enables a file open in vim to be edited using another application and saved.
  nec 'djoshea/vim-autoread'

  -- base64
  nec 'christianrondeau/vim-base64'

  -- Following symlinks
  nec 'aymericbeaumet/vim-symlink'

  -- More performant folding
  -- nec 'Konfekt/FastFold'

  -- Quickfix and location lists
  -- nec 'yssl/QFEnter'

  -- Projections
  nec 'tpope/vim-projectionist'

  -----------------------------------------
  -- LAZY FILETYPE-SPECIFIC PLUGINS
  -----------------------------------------

  -- Saving file-specific syntax match coloring, useful for browsing log text files
  local ft_textlog = { ft = utils.enabled_fts({'text', 'txt', 'log'}) }
  lazy('normful/vim-syntax-match', ft_textlog) -- forked from 'ochaloup/vim-syntax-match'

  -- .gitignore
  local ft_gitignore = { ft = utils.enabled_fts({'gitignore'}) }
  lazy('gisphm/vim-gitignore', ft_gitignore)

  -- Markdown
  local ft_markdown= { ft = utils.enabled_fts({'markdown'}) }
  lazy('plasticboy/vim-markdown', ft_markdown)

  -- Confluence Wiki Markup
  local ft_confluencewiki = { ft = utils.enabled_fts({'confluencewiki'}) }
  lazy('vim-scripts/confluencewiki.vim', ft_confluencewiki)

  -- Thrift
  local ft_thrift = { ft = utils.enabled_fts({'thrift'}) }
  lazy('solarnz/thrift.vim', ft_thrift)

  -- pug (fka Jade)
  local ft_pug = { ft = utils.enabled_fts({'pug'}) }
  lazy('digitaltoad/vim-pug', ft_pug)

  -- ECO
  local ft_eco = { ft = utils.enabled_fts({'eco'}) }
  lazy('AndrewRadev/vim-eco', ft_eco)

  -- CSS
  local ft_css = { ft = utils.enabled_fts({'css', 'scss'}) }
  -- lazy('miripiruni/CSScomb-for-Vim.git', ft_css)

  -- YAML
  local ft_yaml = { ft = utils.enabled_fts({'yaml', 'yml'}) }
  lazy('luan/vim-concourse', ft_yaml)

  -- Helm YAML
  local ft_helm = { ft = utils.enabled_fts({'helm'}) }
  lazy('towolf/vim-helm', ft_helm)

  -- PlantUML
  local ft_puml = { ft = utils.enabled_fts({'plantuml', 'puml'}) }
  lazy('aklt/plantuml-syntax', ft_puml)
  lazy('tyru/open-browser.vim', ft_puml)

  -- JSON
  local ft_json = { ft = utils.enabled_fts({'json', 'json5'}) }
  lazy('tpope/vim-jdaddy', ft_json)
  lazy('GutenYe/json5.vim', ft_json)

  -- CoffeeScript
  local ft_coffee = { ft = utils.enabled_fts({'coffee'}) }
  lazy('kchmck/vim-coffee-script', ft_coffee)
  lazy('lukaszkorecki/CoffeeTags', ft_coffee)

  -- Golang
  local ft_go = { ft = utils.enabled_fts({'go'}) }
  lazy('fatih/vim-go', {
    ft = utils.enabled_fts({'go'}),

    -- https://github.com/fatih/vim-go/issues/3325#issuecomment-1002374302
    commit = '2831f4872431685d28fbe3e567cd539a455fe750',
  })
  lazy('ivy/vim-ginkgo', ft_go)
  lazy('jaisonerick/vim-ginkgo-runner', ft_go)

  -- Ruby
  lazy('vim-ruby/vim-ruby', { ft = utils.enabled_fts({'ruby'}) })
  lazy('tpope/vim-rails', { ft = utils.enabled_fts({'ruby', 'javascript', 'coffee'}) })

  -- Python
  local ft_py = { ft = utils.enabled_fts({'py', 'python'}) }
  lazy('vim-python/python-syntax', ft_py)

  -- GraphQL
  local ft_graphql = { ft = utils.enabled_fts({'graphql'}) }
  lazy('jparise/vim-graphql', ft_graphql)

  -- Jenkinsfile Groovy
  local ft_jenkinsfile = { ft = utils.enabled_fts({'Jenkinsfile'}) }
  lazy('martinda/Jenkinsfile-vim-syntax', ft_jenkinsfile)

  -- Jinja
  local ft_jinja = { ft = utils.enabled_fts({'jinja'}) }
  lazy('Glench/Vim-Jinja2-Syntax', ft_jinja)

  -- AppArmor
  local ft_apparmor = { ft = utils.enabled_fts({'apparmor'}) }
  lazy('ClockworkNet/vim-apparmor', ft_apparmor)

  -- Mustache
  local ft_mustache = { ft = utils.enabled_fts({'mustache'}) }
  lazy('mustache/vim-mustache-handlebars', ft_mustache)

  -----------------------------------------
  -- OTHER LAZY PLUGINS (Maybe not needed?)
  -----------------------------------------

  -- A pack of Hashicorp vim plugins:
  -- vim-consul
  -- vim-nomadproject
  -- vim-ottoproject
  -- vim-packer
  -- vim-terraform
  -- vim-vagrant
  -- vim-vaultproject
  lazy 'hashivim/vim-hashicorp-tools'

  -- Tags
  -- lazy 'ludovicchabant/vim-gutentags'
  -- lazy 'xolox/vim-misc'
  -- lazy('majutsushi/tagbar', { ft = utils.enabled_fts({'go', 'ruby'}) })

  -------------------------------------------------------------------------
  -- AUTO-LOADING PLUGINS WITH MORE THAN ONE LINE OF LUA CONFIG FROM ./plug
  -------------------------------------------------------------------------

  local ok, err = pcall(reload_plugins_packer_config)
  if not ok then print('Reloading packer configs for all plugins failed: ' .. err) end

  -----------------------------------------
  -- USE THE PLUGINS
  -----------------------------------------

  local debug = false
  if debug then print('packer_use_specs: ' .. vim.inspect(packer_use_specs)) end

  packer.use(packer_use_specs)
end

return {
  run = function(method_name)
    packer_setup()
    packer_use()

    print('Running packer.' .. method_name .. '()')
    packer[method_name]()
  end,
}
