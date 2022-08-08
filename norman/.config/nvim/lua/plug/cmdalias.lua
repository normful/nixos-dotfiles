local function configure_bufonly()
  require('utils').nnoremap_silent_bulk({
    ['<Leader>bo'] = '<Cmd>BufOnly<CR>',
  })
end

local function configure_cmdalias()
  configure_bufonly()

  vim.cmd([[command! NormfulOpenTerminal call normful#OpenTerminal()]])
  vim.cmd([[command! NormfulGitBlame call normful#GitBlame()]])

  require('utils').create_augroups({
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

return {
  name = 'coot/cmdalias_vim',
  configure = configure_cmdalias,
  requires = {
    {'coot/CRDispatcher'},
    {'vim-scripts/BufOnly.vim'},
  },
}
