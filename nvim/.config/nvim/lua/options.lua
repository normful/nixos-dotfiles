require('nvchad.options')

local opt = vim.opt_global

-- Colors
opt.termguicolors = true
opt.background = 'dark'

-- Rendering
opt.linespace = 0
opt.lazyredraw = true
opt.redrawtime = 10000
opt.listchars = 'tab:▶ ,eol:■,trail:•'
opt.conceallevel = 2

-- Cursor line
opt.cursorline = true
opt.cursorcolumn = false
opt.scrolloff = 0

-- Bottom line
-- TODO: Adjust any settings that conflict with nvchad settings.
-- Or remove any settings that are not necessary because of nvchad's status lines and other lines
--
opt.showmode = true
opt.shortmess = 'filnxtToOFIc'
opt.showcmd = true
opt.cmdheight = 1

-- Left side
opt.number = true
opt.signcolumn = 'yes:1'

-- Mouse
opt.mouse = 'a'

-- Keyboard
opt.timeout = true
opt.timeoutlen = 500
opt.backspace = 'indent,eol,start' -- allow backspacing over these characters

-- Tab pages (aka tabs)
opt.tabpagemax = 100

-- Windows
opt.splitbelow = true
opt.splitright = true
opt.title = true
opt.titlestring = '%{expand("%:p:s?/Users/.*/code/??")}' -- Assumes repos are at /Users/<username>/code and deletes the /Users/<username>/code/ prefix from the titlestring
opt.hidden = true

-- Reading files
opt.modeline = true
opt.modelines = 5
opt.fileformats = ''

local std_data_dir = vim.fn.stdpath('data') -- Usually: ~/.local/share/nvim
local swap_dir = std_data_dir .. '/my_swap//' -- Need 2 trailing forward slashes to ensure unique swap file names
local backup_dir = std_data_dir .. '/my_backup//' -- This too
local undo_dir = std_data_dir .. '/my_undo' -- But not this one

-- Swap
opt.swapfile = true
opt.directory = swap_dir

-- Backup
opt.backup = true
opt.backupdir = backup_dir
opt.backupcopy = 'yes'

-- Undo
opt.undofile = true
opt.undodir = undo_dir

opt.history = 1000
opt.autoread = true -- automatically reload file changed outside vim

-- Indenting
opt.autoindent = true

-- Searching
opt.ignorecase = true -- case insensitive search
opt.smartcase = true -- case sensitive when uc present
opt.showmatch = false -- do not show matching brackets/parentheses (laggy)
opt.incsearch = true -- incremental search
opt.hlsearch = true -- highlight search terms
opt.gdefault = true -- :s has g flag on by default

-- Line wrapping
opt.wrap = false
opt.linebreak = true -- when wrapping is set, break at words

-- Folding options are set in nvim-ufo config

-- Wildmenu
opt.wildmenu = true
opt.wildmode = 'list:longest,full'

-- Substitution :s/.../... with incremental preview
opt.inccommand = 'nosplit' -- do not show split preview window

-- Usually disable spellcheck because built-in dictionaries are unaware of various words and identifiers
opt.spell = false

-- Only the last window will have a status line
opt.laststatus = 3
