-----------------------------------------
-- NECESSARY PLUGINS
-----------------------------------------

-- Cursor line and cursor column
nec('inkarkat/vim-CursorLineCurrentWindow')

-- Diff two ranges of lines
nec('AndrewRadev/linediff.vim')

-- Automatically causes vim to reload files which have been written on disk
-- but not modified in the buffer since the last write from vim.
-- It enables a file open in vim to be edited using another application and saved.
nec('djoshea/vim-autoread')

-- base64
nec('christianrondeau/vim-base64')

-- Following symlinks
nec('aymericbeaumet/vim-symlink')

-----------------------------------------
-- LAZY FILETYPE-SPECIFIC PLUGINS
-----------------------------------------

-- Saving file-specific syntax match coloring, useful for browsing log text files
local ft_textlog = { ft = utils.enabled_fts({ 'text', 'txt', 'log' }) }
lazy('normful/vim-syntax-match', ft_textlog) -- forked from 'ochaloup/vim-syntax-match'

-- .gitignore
local ft_gitignore = { ft = utils.enabled_fts({ 'gitignore' }) }
lazy('gisphm/vim-gitignore', ft_gitignore)

-- Confluence Wiki Markup
local ft_confluencewiki = { ft = utils.enabled_fts({ 'confluencewiki' }) }
lazy('vim-scripts/confluencewiki.vim', ft_confluencewiki)

-- Thrift
local ft_thrift = { ft = utils.enabled_fts({ 'thrift' }) }
lazy('solarnz/thrift.vim', ft_thrift)

-- pug (fka Jade)
local ft_pug = { ft = utils.enabled_fts({ 'pug' }) }
lazy('digitaltoad/vim-pug', ft_pug)

-- ECO
local ft_eco = { ft = utils.enabled_fts({ 'eco' }) }
lazy('AndrewRadev/vim-eco', ft_eco)

-- CSS
local ft_css = { ft = utils.enabled_fts({ 'css', 'scss' }) }
-- lazy('miripiruni/CSScomb-for-Vim.git', ft_css)

-- YAML
local ft_yaml = { ft = utils.enabled_fts({ 'yaml', 'yml' }) }
lazy('luan/vim-concourse', ft_yaml)

-- Helm YAML
local ft_helm = { ft = utils.enabled_fts({ 'helm' }) }
lazy('towolf/vim-helm', ft_helm)

-- JSON
local ft_json = { ft = utils.enabled_fts({ 'json', 'json5' }) }
lazy('GutenYe/json5.vim', ft_json)

-- CoffeeScript
local ft_coffee = { ft = utils.enabled_fts({ 'coffee' }) }
lazy('kchmck/vim-coffee-script', ft_coffee)
lazy('lukaszkorecki/CoffeeTags', ft_coffee)

-- Golang
lazy('ivy/vim-ginkgo', ft_go)
lazy('jaisonerick/vim-ginkgo-runner', ft_go)

-- Jenkinsfile Groovy
local ft_jenkinsfile = { ft = utils.enabled_fts({ 'Jenkinsfile' }) }
lazy('martinda/Jenkinsfile-vim-syntax', ft_jenkinsfile)

-- Jinja
local ft_jinja = { ft = utils.enabled_fts({ 'jinja' }) }
lazy('Glench/Vim-Jinja2-Syntax', ft_jinja)

-- AppArmor
local ft_apparmor = { ft = utils.enabled_fts({ 'apparmor' }) }
lazy('ClockworkNet/vim-apparmor', ft_apparmor)

-- Mustache
local ft_mustache = { ft = utils.enabled_fts({ 'mustache' }) }
lazy('mustache/vim-mustache-handlebars', ft_mustache)
