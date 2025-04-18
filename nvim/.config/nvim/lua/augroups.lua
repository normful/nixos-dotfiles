local nvim_create_augroup = vim.api.nvim_create_augroup
local nvim_create_autocmd = vim.api.nvim_create_autocmd

local function create_map_command(key, command)
  return string.format([[map <buffer> %s %s]], key, command)
end

nvim_create_augroup('help_augroup', { clear = true })
nvim_create_autocmd('FileType', {
  pattern = 'help',
  group = 'help_augroup',
  command = create_map_command('<C-i>', '<C-]>'),
  once = true,
  desc = 'Map Ctrl-i (Wezterm sends on Cmd-i) to Ctrl-] in help files',
})

nvim_create_augroup('env_augroup', { clear = true })
nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = '*.env',
  group = 'env_augroup',
  command = [[set filetype=config]],
  once = true,
  desc = 'Set filetype for .env files',
})

nvim_create_augroup('quickfix_augroup', { clear = true })
nvim_create_autocmd('FileType', {
  pattern = 'qf',
  group = 'quickfix_augroup',
  command = [[setlocal wrap]],
  once = true,
  desc = 'Enable wrapping in quickfix window',
})

nvim_create_augroup('git_augroup', { clear = true })
nvim_create_autocmd('FileType', {
  pattern = 'gitcommit',
  group = 'git_augroup',
  command = [[setlocal textwidth=80 colorcolumn+=80 spell spelllang=en_us]],
  once = true,
  desc = 'Settings for gitcommit files',
})
nvim_create_autocmd('FileType', {
  pattern = 'gitrebase',
  group = 'git_augroup',
  command = [[setlocal textwidth=80 colorcolumn+=80 nospell]],
  once = true,
  desc = 'Settings for gitrebase files',
})

nvim_create_augroup('markdown_augroup', { clear = true })
nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  group = 'markdown_augroup',
  command = [[setlocal nospell]],
  once = true,
  desc = 'No spellcheck in Markdown files',
})

nvim_create_augroup('javascript_augroup', { clear = true })
nvim_create_autocmd('FileType', {
  pattern = 'javascript',
  group = 'javascript_augroup',
  command = create_map_command('<Leader>r', '<Cmd>AsyncRun -mode=term -focus=1 -pos=right -cols=70 node %<CR>'),
  once = true,
  desc = 'Run this JS file with node',
})

nvim_create_augroup('typescript_augroup', { clear = true })
nvim_create_autocmd('FileType', {
  pattern = 'typescript',
  group = 'typescript_augroup',
  command = create_map_command('<Leader>r', '<Cmd>AsyncRun -mode=term -focus=1 -pos=right -cols=70 ts-node %<CR>'),
  once = true,
  desc = 'Run this TS file with ts-node',
})
