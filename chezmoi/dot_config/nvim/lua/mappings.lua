local map = vim.keymap.set

------------------------------------------------
-- Disable Arrow Keys in Normal and Insert modes
------------------------------------------------

map({ 'i' }, '<Up>', '<Cmd>echoerr "Use k instead"<CR>', { desc = 'Disable <Up>: Use k' })
map({ 'i' }, '<Down>', '<Cmd>echoerr "Use j instead"<CR>', { desc = 'Disable <Down>: Use j' })
map({ 'i' }, '<Left>', '<Cmd>echoerr "Use h instead"<CR>', { desc = 'Disable <Left>: Use h' })
map({ 'i' }, '<Right>', '<Cmd>echoerr "Use l instead"<CR>', { desc = 'Disable <Right>: Use l' })

------------------------------------------------
-- Visual Mode Mappings (Mode 'x')
------------------------------------------------

-- Temporarily disabling because of conflict with Neorg
---- map('x', '<', '<gv', { desc = 'Indent line without exiting visual mode' })
---- map('x', '>', '>gv', { desc = 'Unindent line without exiting visual mode' })

-- Navigate wrapped lines in Visual mode
map('x', 'j', 'gj', { desc = 'Move down by visual line' })
map('x', 'k', 'gk', { desc = 'Move up by visual line' })
map('x', '^', 'g^', { desc = 'Move to visual beginning of line' })
map('x', '0', 'g0', { desc = 'Move to visual beginning of line' })
map('x', '$', 'g$', { desc = 'Move to visual end of line' })

------------------------------------------------
-- Command-line Mode Mappings (Mode 'c')
------------------------------------------------

map('c', '<C-j>', '<Down>', { desc = 'Navigate down in command line history/completion' })
map('c', '<C-k>', '<Up>', { desc = 'Navigate up in command line history/completion' })
map('c', '<C-h>', '<S-left>', { desc = 'Move cursor left' })
map('c', '<C-l>', '<S-right>', { desc = 'Move cursor right' })
map(
  'c',
  'w!!',
  'execute "silent! write !SUDO_ASKPASS=`which ssh-askpass` sudo tee % >/dev/null" <bar> edit!',
  { desc = 'Write buffer using sudo even after forgetting to start nvim with sudo' }
)

------------------------------------------------
-- Terminal Mode Mappings (Mode 't')
------------------------------------------------

map({ 't', 'n' }, '<Localleader>t', '<Cmd>ToggleNvchadTerminal<CR>', { desc = 'Toggle terminal' })
map('t', '<Esc>', '<C-\\><C-n>', { desc = 'Enter Normal mode from terminal' })
map('t', '<C-w>', '<C-\\><C-n><C-w>w', { desc = 'Enter Normal mode and switch window' })

------------------------------------------------
-- Normal Mode Mappings (Mode 'n')
------------------------------------------------

map(
  'n',
  'Q',
  '<Cmd>echoerr "Q enters command-line mode usually, but has been disabled"<CR>',
  { desc = 'Disable Q (Ex mode: persistent command line mode)' }
)

map('n', 'D', '<Cmd>echoerr "Use [Right Command + d] to scroll down"<CR>', { desc = 'Disable D: Use Cmd+j/d to scroll' })
map('n', 'U', '<Cmd>echoerr "Use [Right Command + u] to scroll up"<CR>', { desc = 'Disable U: Use Cmd+k/u to scroll' })

map('n', 'Y', 'yy', { desc = 'Yank whole line' })

map('n', '<Leader>em', '<Cmd>100vsplit ~/code/nixos-dotfiles/mac/cyan/packages.nix<CR>', { desc = 'Edit cyan Nix config' })
map('n', '<Leader>ed', '<Cmd>100vsplit ~/code/nixos-dotfiles/wsl/duro/my-config.nix<CR>', { desc = 'Edit duro Nix config' })

map('n', '<Leader>eg', '<Cmd>100vsplit ~/code/nixos-dotfiles/chezmoi/dot_gitconfig.tmpl<CR>', { desc = 'Edit gitconfig' })
map(
  'n',
  '<Leader>ew',
  '<Cmd>100vsplit ~/code/nixos-dotfiles/chezmoi/dot_config/wezterm/wezterm.lua.tmpl<CR>',
  { desc = 'Edit wezterm config' }
)
--[[
map('n', '<Leader>ek', '<Cmd>100vsplit ~/code/nixos-dotfiles/chezmoi/dot_config/kitty/kitty.conf<CR>', { desc = 'Edit kitty config' })
map('n', '<Leader>et', '<Cmd>100vsplit ~/code/nixos-dotfiles/chezmoi/dot_config/ghostty/config<CR>', { desc = 'Edit ghostty config' })
]]
map(
  'n',
  '<Leader>ef',
  '<Cmd>100vsplit ~/code/nixos-dotfiles/chezmoi/dot_config/fish/config.fish.tmpl<CR>',
  { desc = 'Edit fish config' }
)

-- First set of mappings, intended for use with Neovide
map('n', '<D-d>', '20j', { desc = '[Cmd+d] Scroll down 20 lines' })
map('n', '<D-u>', '20k', { desc = '[Cmd+u] Scroll up 20 lines' })
map('n', '<D-w>', '<C-w>w', { desc = '[Cmd+w] Next window' })
map('n', '<D-b>', '<Cmd>bnext<CR>', { desc = '[Cmd+b] Next buffer' })

-- Same copy of the above mappings, intended for use with nvim inside Wezterm
-- These rely on Wezterm mappings that send these function keys
map('n', '<F13>', '20j', { desc = '[Cmd+d] Scroll down 20 lines' })
map('n', '<F14>', '20k', { desc = '[Cmd+u] Scroll up 20 lines' })
map('n', '<F15>', '<C-w>w', { desc = '[Cmd+w] Next window' })
map('n', '<F16>', '<Cmd>bnext<CR>', { desc = '[Cmd+b] Next buffer' })

map('n', '<C-S-j>', '<Cmd>lnext<CR>', { desc = 'Go to next location list item' })
map('n', '<C-S-k>', '<Cmd>lprevious<CR>', { desc = 'Go to previous location list item' })

-- map('n', '/', '/\\v', { desc = "Search with 'very magic' regex" })

map('n', 'zl', 'zL', { desc = 'Big scroll right' })
map('n', 'zh', 'zH', { desc = 'Big scroll left' })

map('n', '<Localleader>h', '<Cmd>set hlsearch!<CR>', { desc = 'Toggle search results highlight' })
map('n', '<Localleader>w', '<Cmd>set wrap!<CR>', { desc = 'Toggle line wrapping' })

map('n', '<Localleader><Tab>', ':call normful#SetTabSettings()<CR>', { desc = 'Set tab settings' })

map('n', '<Localleader>H', '<Cmd>windo wincmd K<CR>', { desc = 'Rearrange windows in hsplit' })
map('n', '<Localleader>V', '<Cmd>windo wincmd H<CR>', { desc = 'Rearrange windows in vsplit' })

map('n', '<Localleader>zt', function()
  require('nvchad.themes').open()
end, { desc = 'Pick nvchad theme' })

map('n', '<Localleader>zc', '<cmd>NvCheatsheet<CR>', { desc = 'Toggle cheatsheet' })

local helpers = require('mappings-helpers')
local open_term = helpers.open_nvchad_term
local term_id1 = 'term_id1'

-- Commands below that start with :Git need two carriage returns (<CR>) so that
-- 'Press ENTER or type command to continue' is not displayed

map('n', '<Leader>gb', '<Cmd>normful#GitBlame<CR><F15><CR>', { desc = 'git blame' })

map('n', '<Leader>gd', '<Cmd>Git diff<CR>', { desc = 'git diff' })

map('n', '<Leader>gw', '<Cmd>Git w<CR><CR><CR>', { desc = 'git stage all and commit' })
map('n', '<Leader>gsh', '<Cmd>Git show<CR><CR>', { desc = 'git show' })
map('n', '<Leader>gs', '<Cmd>Git status<CR>', { desc = 'git status' })

map('n', '<Leader>gl', open_term(term_id1, 'git lforvim "FILEPATH"'), { desc = 'git log this file' })
map('n', '<Leader>gll', open_term(term_id1, 'git llforvim "FILEPATH"'), { desc = 'git log this file with stats' })
map('n', '<Leader>glll', open_term(term_id1, 'git lllforvim "FILEPATH"'), { desc = 'git log this file with patches' })
map('n', '<Leader>gppl', open_term(term_id1, 'git pplforvim "FILEPATH"'), { desc = 'git shortlog' })

map({ 'n', 'i', 'v' }, '<F12>', function()
  print('Debugging mode - press any key (ESC to exit)')
  local char = vim.fn.getchar()
  print('Received keycode: ' .. char .. ' As string: ' .. vim.fn.nr2char(char))
end)
