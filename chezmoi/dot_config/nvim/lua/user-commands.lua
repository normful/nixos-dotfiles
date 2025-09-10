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
