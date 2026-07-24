local map = vim.keymap.set
-- file-specific quick-open: <Leader>e<key> → open config file
local config_files = {
  m = '~/code/nixos-dotfiles/mac/cyan/configuration.nix',
  d = '~/code/nixos-dotfiles/wsl/duro/my-config.nix',
  g = '~/code/nixos-dotfiles/chezmoi/dot_gitconfig.tmpl',
  w = '~/code/nixos-dotfiles/chezmoi/dot_config/wezterm/wezterm.lua.tmpl',
  k = '~/code/nixos-dotfiles/chezmoi/dot_config/kitty/kitty.conf',
  t = '~/code/nixos-dotfiles/chezmoi/dot_config/ghostty/config',
  f = '~/code/nixos-dotfiles/chezmoi/dot_config/fish/config.fish.tmpl',
}
for key, path in pairs(config_files) do
  map('n', '<Leader>e' .. key, '<Cmd>100vsplit ' .. path .. '<CR>', { desc = 'Edit ' .. key .. ' config' })
end

-- arrow keys: disabled in insert mode
map({ 'i' }, '<Up>', '<Cmd>echoerr "Use k instead"<CR>', { desc = 'Disable <Up>' })
map({ 'i' }, '<Down>', '<Cmd>echoerr "Use j instead"<CR>', { desc = 'Disable <Down>' })
map({ 'i' }, '<Left>', '<Cmd>echoerr "Use h instead"<CR>', { desc = 'Disable <Left>' })
map({ 'i' }, '<Right>', '<Cmd>echoerr "Use l instead"<CR>', { desc = 'Disable <Right>' })

-- visual mode: wrapped-line navigation
map('x', 'j', 'gj', { desc = 'Visual line down' })
map('x', 'k', 'gk', { desc = 'Visual line up' })
map('x', '^', 'g^', { desc = 'Visual line first char' })
map('x', '0', 'g0', { desc = 'Visual line column 0' })
map('x', '$', 'g$', { desc = 'Visual line end' })

-- command-line mode: ctrl navigation
map('c', '<C-j>', '<Down>', { desc = 'Cmdline history down' })
map('c', '<C-k>', '<Up>', { desc = 'Cmdline history up' })
map('c', '<C-h>', '<S-left>', { desc = 'Cmdline cursor left' })
map('c', '<C-l>', '<S-right>', { desc = 'Cmdline cursor right' })
map(
  'c',
  'w!!',
  'execute "silent! write !SUDO_ASKPASS=`which ssh-askpass` sudo tee % >/dev/null" <bar> edit!',
  { desc = 'Sudo write' }
)

-- terminal mode
map({ 't', 'n' }, '<Localleader>t', '<Cmd>ToggleNvchadTerminal<CR>', { desc = 'Toggle terminal' })
map('t', '<Esc>', '<C-\\><C-n>', { desc = 'Terminal normal mode' })
map('t', '<C-w>', '<C-\\><C-n><C-w>w', { desc = 'Terminal next window' })

-- normal mode: disable noisy keys
map('n', 'Q', '<Cmd>echoerr "Q disabled"<CR>', { desc = 'Disable Q' })
map('n', 'D', '<Cmd>echoerr "Use Cmd+d to scroll"<CR>', { desc = 'Disable D' })
map('n', 'U', '<Cmd>echoerr "Use Cmd+u to scroll"<CR>', { desc = 'Disable U' })

map('n', 'Y', 'yy', { desc = 'Yank whole line' })
map('n', '<C-S-j>', '<Cmd>lnext<CR>', { desc = 'Location list next' })
map('n', '<C-S-k>', '<Cmd>lprevious<CR>', { desc = 'Location list prev' })
map('n', 'zl', 'zL', { desc = 'Big scroll right' })
map('n', 'zh', 'zH', { desc = 'Big scroll left' })

-- <Localleader> mappings
map('n', '<Localleader>h', '<Cmd>set hlsearch!<CR>', { desc = 'Toggle hlsearch' })
map('n', '<Localleader>w', '<Cmd>set wrap!<CR>', { desc = 'Toggle wrap' })
map('n', '<Localleader><Tab>', ':call normful#SetTabSettings()<CR>', { desc = 'Set tab settings' })
map('n', '<Localleader>H', '<Cmd>windo wincmd K<CR>', { desc = 'Windows to hsplit' })
map('n', '<Localleader>V', '<Cmd>windo wincmd H<CR>', { desc = 'Windows to vsplit' })
map('n', '<Localleader>zt', function()
  require('nvchad.themes').open()
end, { desc = 'Pick theme' })
map('n', '<Localleader>zc', '<cmd>NvCheatsheet<CR>', { desc = 'Toggle cheatsheet' })
map('n', '<Localleader>y', '<Cmd>LookupYomitanDefinitions<CR>', { desc = 'Yomitan definitions' })

-- markdown visual: quoting / listifying
local augroup_md = vim.api.nvim_create_augroup('MarkdownMappings', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  group = augroup_md,
  callback = function()
    map('x', '<Leader>q', function()
      vim.cmd('normal! gv')
      vim.cmd("'<,'>s/^/> /")
      vim.cmd('nohlsearch')
    end, { desc = 'Quote lines (prepend > )' })
    map('x', '<Leader>l', function()
      vim.cmd('normal! gv')
      vim.cmd("'<,'>s/^/- /")
      vim.cmd('nohlsearch')
    end, { desc = 'Listify lines (prepend - )' })
  end,
})

-- neovim GUI / terminal fallback pairs
local function neovide_or_term(neovide_lhs, neovide_rhs, desc, term_rhs)
  if vim.g.neovide then
    map('n', neovide_lhs, neovide_rhs, { desc = desc })
  end
  if term_rhs then
    map('n', term_rhs[1], term_rhs[2], { desc = term_rhs[3] })
  end
end
neovide_or_term('<D-d>', '20j', '[Cmd+d] Scroll 20 down', { '<F13>', '20j', '[F13] Scroll 20 down' })
neovide_or_term('<D-u>', '20k', '[Cmd+u] Scroll 20 up', { '<F14>', '20k', '[F14] Scroll 20 up' })
neovide_or_term('<D-w>', '<C-w>w', '[Cmd+w] Next window', { '<F15>', '<C-w>w', '[F15] Next window' })
neovide_or_term('<D-b>', '<Cmd>bnext<CR>', '[Cmd+b] Next buffer', { '<F16>', '<Cmd>bnext<CR>', '[F16] Next buffer' })

-- neovim GUI: zoom scale
if vim.g.neovide then
  map('n', '<D-=>', function()
    vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * 1.25
  end, { desc = 'Zoom in' })
  map('n', '<D-->', function()
    vim.g.neovide_scale_factor = vim.g.neovide_scale_factor / 1.25
  end, { desc = 'Zoom out' })
end

-- git
local helpers = require('mappings-helpers')
local open_term = helpers.open_nvchad_term
local tid = 'term_id1'

map('n', '<Leader>gb', '<Cmd>normful#GitBlame<CR><F15><CR>', { desc = 'Git blame' })
map('n', '<Leader>gd', '<Cmd>Git diff<CR>', { desc = 'Git diff' })
map('n', '<Leader>gw', '<Cmd>NormfulGitStageAllAndCommit<CR>', { desc = 'Git stage+commit (buf dir)' })
map('n', '<Leader>gsh', '<Cmd>Git show<CR><CR>', { desc = 'Git show' })
map('n', '<Leader>gs', '<Cmd>Git status<CR>', { desc = 'Git status' })
map('n', '<Leader>gl', open_term(tid, 'git lforvim "FILEPATH"'), { desc = 'Git log (file)' })
map('n', '<Leader>gll', open_term(tid, 'git llforvim "FILEPATH"'), { desc = 'Git log w/ stats' })
map('n', '<Leader>glll', open_term(tid, 'git lllforvim "FILEPATH"'), { desc = 'Git log w/ patches' })
map('n', '<Leader>gppl', open_term(tid, 'git pplforvim "FILEPATH"'), { desc = 'Git shortlog' })

-- zk index
map('n', '<Leader>zi', '<Cmd>silent !cd $HOME/code/alcove && zk index<CR>', { desc = 'Index zk notes', noremap = true })

-- debug: capture key code
map({ 'n', 'i', 'v' }, '<S-F4>', function()
  print('Debug mode — press any key (ESC to exit)')
  local char = vim.fn.getchar()
  print('Keycode: ' .. char .. ' (' .. vim.fn.nr2char(char) .. ')')
end, { desc = 'Debug key code' })
