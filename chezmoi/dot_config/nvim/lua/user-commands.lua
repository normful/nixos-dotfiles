-- General user-defined commands (aka Ex commands or colon commands)
-- See :help user-commands
vim.cmd([[command! -nargs=1 -range SuperRetab <line1>,<line2>s/\v%(^ *)@<= {<args>}/\t/g]])
vim.cmd([[command! -range Listfy <line1>,<line2>s/^\(\s*\)\(\w\+.*\)/\1- [ ] \2/g]])
vim.cmd([[command! -range Bulletfy <line1>,<line2>s/^\(\s*\)-\s\(\w\+.*\)/\1- [ ] \2/g]])
vim.cmd([[command! -range=% WordFrequency <line1>,<line2>call normful#WordFrequency()]])
vim.cmd([[command! NormfulGitBlame call normful#GitBlame()]])

local term_id = 'my_toggle_term'
vim.api.nvim_create_user_command('ToggleNvchadTerminal', function()
  local term = require('nvchad.term')
  local helpers = require('mappings-helpers')
  term.toggle({
    id = term_id,
    pos = 'sp',
    -- Options passed directly to the underlying terminal opening function vim.fn.termopen.
    -- See :h jobstart-options for other potential options here.
    termopen_opts = {
      cwd = helpers.get_current_buffer_git_root(),
      clear_env = true,
    },
  })
end, {
  nargs = 0,
  desc = 'Toggle term in hsplit',
})

vim.api.nvim_create_user_command('MakeItalic', function()
  local keys = vim.api.nvim_replace_termcodes('ciw*<C-r>"*<esc>b', true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', true)
end, { nargs = 0 })

vim.api.nvim_create_user_command('MakeBold', function()
  local keys = vim.api.nvim_replace_termcodes('ciw**<C-r>"**<esc>bb', true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', true)
end, { nargs = 0 })

-- Inserts links from clipboard or creates new Zk links
-- Handles both normal and visual mode
vim.api.nvim_create_user_command('NormfulInsertLink', function(opts)
  if vim.fn.exists(':ZkInsertLink') ~= 2 then
    error('Command not available: ZkInsertLink')
  end

  if vim.fn.exists(':ZkInsertLinkAtSelection') ~= 2 then
    error('Command not available: ZkInsertLinkAtSelection')
  end

  -- Get clipboard content and define URL pattern for validation
  local clipboard = vim.fn.getreg('+')
  local url_pattern = '^https?://[^%s]+$'

  -- Check if clipboard contains a valid URL
  -- Invalid if: empty, too long, contains control chars, or doesn't match URL pattern
  if
    not clipboard
    or clipboard == ''
    or #clipboard > 2000
    or string.match(clipboard, '[%z\1-\31\127-\255]')
    or not string.match(clipboard, url_pattern)
  then
    -- No valid URL in clipboard: use Zk commands to create/select links
    if opts.range == 2 then
      -- Visual selection: use ZkInsertLinkAtSelection with visual range
      vim.cmd("'<,'>ZkInsertLinkAtSelection")
    else
      -- No visual selection: use ZkInsertLink for interactive link creation
      vim.cmd('ZkInsertLink')
    end
    return
  end

  -- Valid URL in clipboard: use mkdnflow for link insertion
  local mkdnflow = require('mkdnflow')

  if opts.range > 0 then
    -- Some range selected: create link with selection as text
    mkdnflow.links.createLink({
      from_clipboard = true,
      range = true,
    })
  else
    -- No range: create link at cursor with clipboard URL
    mkdnflow.links.createLink({
      from_clipboard = true,
    })
  end

  -- Clear clipboard after successful link creation to prevent reuse
  vim.fn.setreg('+', '')
end, {
  nargs = 0,

  -- Allow range to be passed for visual selections
  range = true,
})
