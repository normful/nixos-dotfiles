local function configure_bufonly()
  utils.nnoremap_silent_bulk({
    ['<Leader>bo'] = '<Cmd>BufOnly<CR>',
  })
end

local function configure_cmdalias()
  vim.cmd([[command! NormfulOpenTerminal call NormfulOpenTerminal()]])
  vim.cmd([[command! NormfulGitBlame call NormfulGitBlame()]])

  utils.create_augroups({
    cmdalias_augroup = {
      {'VimEnter', '*', 'CmdAlias Vsp vsp'},
      {'VimEnter', '*', 'CmdAlias Vps vsp'},
      {'VimEnter', '*', 'CmdAlias vps vsp'},

      {'VimEnter', '*', 'CmdAlias Sp sp'},

      {'VimEnter', '*', 'CmdAlias W! w!'},
      {'VimEnter', '*', 'CmdAlias w w!'},
      {'VimEnter', '*', 'CmdAlias W w!'},
      {'VimEnter', '*', 'CmdAlias Q! q!'},
      {'VimEnter', '*', 'CmdAlias Wq! wq!'},
      {'VimEnter', '*', 'CmdAlias WQ! wq!'},

      {'VimEnter', '*', 'CmdAlias ch checkhealth'},

      {'VimEnter', '*', 'CmdAlias term NormfulOpenTerminal'},
      {'VimEnter', '*', 'CmdAlias ter NormfulOpenTerminal'},
      {'VimEnter', '*', 'CmdAlias te NormfulOpenTerminal'},

      {'VimEnter', '*', 'CmdAlias Gbl NormfulGitBlame'},
      {'VimEnter', '*', 'CmdAlias Gbl NormfulGitBlame'},
    },
  })
end

configure_bufonly()
configure_cmdalias()
