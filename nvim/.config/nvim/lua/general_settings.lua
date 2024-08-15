local function add_general_settings()
  local g = vim.g
  local utils = require("utils")
  local set = utils.set

  -- Run :checkhealth to see status of providers

  -- Colors
  set('termguicolors', true)
  set('background', 'dark')

  -- Rendering
  set('linespace', 0)
  set('lazyredraw', true)
  set('redrawtime', 10000)
  set('listchars', 'tab:▶ ,eol:■,trail:•')
  set('conceallevel', 2)

  -- Cursor line
  set('cursorline', true)
  set('cursorcolumn', false)
  set('scrolloff', 0)

  -- Bottom line
  set('showmode', true)
  set('shortmess', 'filnxtToOFIc')
  set('showcmd', true)
  set('cmdheight', 1)

  -- Left side
  set('number', true)
  set('signcolumn', 'yes:1')

  -- Mouse
  set('mouse', 'a')

  -- Keyboard
  set('timeout', true)
  set('timeoutlen', 500)
  set('backspace', 'indent,eol,start') -- allow backspacing over these characters

  -- Tab pages (aka tabs)
  set('tabpagemax', 100)

  -- Windows
  set('splitbelow', true)
  set('splitright', true)
  set('title', true)
  set('titlestring', '%{expand(\"%:p:s?/Users/.*/code/??\")}') -- Assumes repos are at /Users/<username>/code and deletes the /Users/<username>/code/ prefix from the titlestring
  set('hidden', true)

  -- Reading files
  set('modeline', true)
  set('modelines', 5)
  set('fileformats', '')

  local std_data_dir = vim.fn.stdpath("data") -- Usually: ~/.local/share/nvim
  local swap_dir = std_data_dir .. '/my_swap'
  local backup_dir = std_data_dir .. '/my_backup'
  local undo_dir = std_data_dir .. '/my_undo'

  -- Swap
  set('swapfile', true)
  set('directory', swap_dir)

  -- Backup
  set('backup', true)
  set('backupdir', backup_dir)
  set('backupcopy', 'yes')

  -- Undo
  set('undofile', true)
  set('undodir', undo_dir)

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

  -- Folding is also in nvim-ufo config
  set('foldcolumn', '0')
  set('foldlevel', 99)
  set('foldlevelstart', 99)
  set('foldenable', true)

  -- Wildmenu
  set('wildmenu', true)
  set('wildmode', 'list:longest,full')

  -- Substitution :s/.../... with incremental preview
  set('inccommand', 'nosplit') -- do not show split preview window

  -- Usually disable spellcheck because built-in dictionaries are unaware of various words and identifiers
  set('spell', false)
end

add_general_settings()
