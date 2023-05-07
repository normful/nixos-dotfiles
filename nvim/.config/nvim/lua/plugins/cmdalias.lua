local function configure_cmdalias()
  local utils = require('utils')

  vim.cmd([[command! NormfulOpenTerminal call normful#OpenTerminal()]])
  vim.cmd([[command! NormfulGitBlame call normful#GitBlame()]])

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

return {
  'coot/cmdalias_vim',
  dependencies = {
    { 'coot/CRDispatcher', lazy = false, },
  },
  config = configure_cmdalias,
  lazy = false,
}
