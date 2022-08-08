local g = vim.g

local globals = require('globals')
local home = globals.home

local utils = require('utils')
local set = utils.set
local has = utils.has

-- o: global
-- wo: window
-- bo: buffer
-- Some settings require both {o, wo} or both {o, bo}
-- Some settings only need {bo}
local o, wo, bo = vim.o, vim.wo, vim.bo

-- Run :checkhealth to see status of these providers

-- Disable Python 2 support
g.loaded_python_provider = 0

-- If you really want Python 2 support, then the Python2 provider requires installing https://github.com/neovim/pynvim
-- If using MacOS python2 (not brew), pip will not be installed. Install pip and pynvim:
--   sudo -H python -m ensurepip
--   pip install pynvim --user

-- Python3 provider: Requires installing https://github.com/neovim/pynvim
--   pip3 install pynvim

-- Explicitly set Python3 provider, to prevent slow startup
-- https://www.reddit.com/r/neovim/comments/ksf0i4/slow_startup_time_when_opening_python_files_with/giigobp?utm_source=share&utm_medium=web2x&context=3
g.python3_host_prog = '/run/current-system/sw/bin/python3'

-- Node.js provider: https://github.com/neovim/node-client
--   npm install -g neovim
-- g.node_host_prog = '/usr/local/lib/node_modules/neovim'

-- Disable unneeded built-in plugins
local disabled_built_ins = {
  'gzip',
  'man',

  -- andymass/vim-matchup is better than these:
  'matchit',
  'matchparen',

  'netrwPlugin',
  'shada_plugin',
  'tar',
  'tarPlugin',
  'zip',
  'zipPlugin',
}
for i = 1, #disabled_built_ins do
  g['loaded_' .. disabled_built_ins[i]] = 1
end

-- Colors
set('termguicolors', true)
set('background', 'dark')

-- Rendering
set('linespace', 0)
set('lazyredraw', true)
set('redrawtime', 10000)
set('listchars', 'tab:▶ ,eol:■,trail:•')

-- Cursor line
set('cursorline', true, {o, wo})
set('cursorcolumn', false, {o, wo})
set('scrolloff', 0)

-- Bottom line
set('showmode', true)
set('shortmess', 'filnxtToOFIc')
set('showcmd', true)
set('cmdheight', 1)

-- Left side
set('number', true)
set('signcolumn', 'yes:1', {o, wo})

-- Mouse
set('mouse', 'a')

-- Keyboard
set('timeoutlen', 500)
set('backspace', 'indent,eol,start') -- allow backspacing over these characters
if vim.env.TMUX == '' then
  set('clipboard', 'unnamed')
end

-- Tab pages (aka tabs)
set('tabpagemax', 100)

-- Windows
set('splitbelow', true)
set('splitright', true)
set('title', true)
set('hidden', true)

-- Reading files
set('modeline', true)
set('modelines', 5)

-- Swap
set('swapfile', true)
set('directory', globals.swap_dir)

-- Backup
set('backup', true)
set('backupdir', globals.backup_dir)
set('backupcopy', 'yes')

-- Undo
set('undofile', true)
set('undodir', globals.undo_dir)

set('history', 1000)
set('autoread', true) -- automatically reload file changed outside vim

-- Indenting
set('autoindent', true)

-- Searching
set('ignorecase', true) -- case insensitive search
set('smartcase', true) -- case sensitive when uc present
set('showmatch', false) -- do not show matching brackets/parentheses (laggy)
set('incsearch', true) -- incremental search
set('hlsearch', true) -- highlight search terms
set('gdefault', true) -- :s has g flag on by default

-- Line wrapping
set('wrap', false)
set('linebreak', true) -- when wrapping is set, break at words

-- Folding
set('foldenable', true) -- enable folding
set('foldlevel', 99, {o, wo}) -- default fold level
set('foldlevelstart', 99) -- open some folds by default

-- Wildmenu
set('wildmenu', true)
set('wildmode', 'list:longest,full')

-- Substitution :s/.../... with incremental preview
set('inccommand', 'nosplit') -- do not show split preview window

-- Usually disable spellcheck because built-in dictionaries are unaware of various words and identifiers
set('spell', false)
