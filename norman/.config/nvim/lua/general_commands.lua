-- General user-defined commands (aka Ex commands or colon commands) {{{1
-- See :help user-commands
vim.cmd([[command! -nargs=1 -range SuperRetab <line1>,<line2>s/\v%(^ *)@<= {<args>}/\t/g]])
vim.cmd([[command! -range Listfy <line1>,<line2>s/^\(\s*\)\(\w\+.*\)/\1- [ ] \2/g]])
vim.cmd([[command! -range Bulletfy <line1>,<line2>s/^\(\s*\)-\s\(\w\+.*\)/\1- [ ] \2/g]])
vim.cmd([[command! -range=% WordFrequency <line1>,<line2>call normful#WordFrequency()]])
