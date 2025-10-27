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

  -- Detect if we're in visual mode
  local mode = vim.api.nvim_get_mode().mode
  local in_visual_mode = mode == 'v' or mode == 'V' or mode == '\22' -- \22 is Ctrl-V (visual block)

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
    if in_visual_mode then
      -- Visual selection: exit visual mode first, then call ZkInsertLinkAtSelection
      -- The '< and '> marks will be preserved and used by get_lsp_location_from_selection()
      -- We MUST exit visual mode because zk's get_lsp_location_from_selection() expects
      -- to be called from normal mode with '< and '> marks from a previous selection
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
      vim.schedule(function()
        require('zk.commands').get('ZkInsertLinkAtSelection')()
      end)
    else
      -- No visual selection: use ZkInsertLink for interactive link creation
      vim.cmd('ZkInsertLink')
    end
    return
  end

  if vim.fn.exists(':MkdnCreateLinkFromClipboard') ~= 2 then
    error('Command not available: MkdnCreateLinkFromClipboard')
  end

  -- Valid URL in clipboard: use mkdnflow for link insertion
  -- Call without range to let mkdnflow handle visual mode directly
  vim.cmd('MkdnCreateLinkFromClipboard')

  -- Clear clipboard after successful link creation to prevent reuse
  vim.fn.setreg('+', '')
end, {
  nargs = 0,
  -- Note: range not needed since we use <Cmd> mapping which keeps visual mode active
})
