local function add_general_augroups()
  utils.create_augroups({
  -- TODO(norman): Uncomment
  --terminal_no_number_augroup = {
  --  {'TermOpen,BufWinEnter', '*', [[call normful#TerminalNoNumber()]]},
  --},

  --terminal_no_nested_nvim_augroup = {
  --  {'VimEnter', '*', [[call normful#SplitWithoutNesting()]]},
  --},

    help_augroup = {
      {'FileType', 'help', [[map <buffer> <C-i> <C-]>]]},
    },

    quickfix_augroup = {
      {'FileType', 'qf', [[setlocal wrap]]},
    },

    vimscript_augroup = {
      {'FileType', 'vim', [[setlocal tabstop=4 softtabstop=4 shiftwidth=4 expandtab foldmethod=marker]]},
    },

    git_augroup = {
      {'FileType', 'gitconfig', [[setlocal tabstop=4 softtabstop=4 shiftwidth=4 expandtab]]},
      {'FileType', 'gitcommit', [[setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab textwidth=80 colorcolumn+=80 spell spelllang=en_us]]},
      {'FileType', 'gitrebase', [[setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab textwidth=80 colorcolumn+=80 nospell]]},
    },

    lua_augroup = {
      {'FileType', 'lua', [[setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab]]},
    },

    markdown_augroup = {
      {'FileType', 'pandoc,markdown', [[setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab nospell]]},
    },
  })
end

add_general_augroups()
