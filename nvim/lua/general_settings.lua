local function add_general_settings()
  local g = vim.g
  local set = utils.set

  -- o: global
  -- wo: window
  -- bo: buffer
  -- Some settings require both {o, wo} or both {o, bo}
  -- Some settings only need {bo}
  local o, wo, bo = vim.o, vim.wo, vim.bo

  -- Run :checkhealth to see status of these providers

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

  -- Expanded: ~/.cache/nvim
  local cache_dir = os.getenv("HOME") .. '/.cache/nvim'

  -- Expanded: ~/.cache/nvim/swap
  local swap_dir = cache_dir .. '/swap'

  -- Expanded: ~/.cache/nvim/backup
  local backup_dir = cache_dir .. '/backup'

  -- Expanded: ~/.cache/nvim/undo
  local undo_dir = cache_dir .. '/undo'

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
end

add_general_settings()
