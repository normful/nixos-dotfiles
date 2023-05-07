local function add_general_augroups()
  local utils = require("utils")

  utils.create_augroups({
    help_augroup = {
      {'FileType', 'help', [[map <buffer> <C-i> <C-]>]]},
    },

    env_augroup = {
      {'BufRead,BufNewFile', '*.env', [[set filetype=config]]},
    },

    quickfix_augroup = {
      {'FileType', 'qf', [[setlocal wrap]]},
    },

    git_augroup = {
      {'FileType', 'gitcommit', [[setlocal textwidth=80 colorcolumn+=80 spell spelllang=en_us]]},
      {'FileType', 'gitrebase', [[setlocal textwidth=80 colorcolumn+=80 nospell]]},
    },

    markdown_augroup = {
      {'FileType', 'markdown', [[setlocal nospell]]},
    },

    -- Use these kinds of mappings that call AsyncRun, instead of using https://github.com/fboender/bexec

    javascript_augroup = {
      {'FileType', 'javascript', [[map <buffer> <Leader>r <Cmd>AsyncRun -mode=term -focus=1 -pos=right -cols=70 node %<CR>]]},
    },

    typescript_augroup = {
      {'FileType', 'typescript', [[map <buffer> <Leader>r <Cmd>AsyncRun -mode=term -focus=1 -pos=right -cols=70 ts-node %<CR>]]},
    },

    -- Avoid putting tab-related settings here, and instead use FotiadisM/tabset.nvim
  })
end

add_general_augroups()
