local function ar_cmd(cmd_txt)
  -- Note: The extra sleep 300 is to workaround nvim_terminal_emulator's behavior
  -- of closing the window after the process finishes in a :terminal.
  -- Vim's terminal doesn't do that.
  return ('<Cmd>AsyncRun -mode=term -focus=1 -pos=right -cols=120 -strip %s && sleep 600<CR><C-\\><C-n>'):format(cmd_txt)
end

local function quick_look_ar_cmd(cmd_txt)
  return ('<Cmd>AsyncRun -mode=term -focus=1 -pos=right -cols=120 -strip %s<CR>'):format(cmd_txt)
end

local function configure_git_mappings()
  local l   = ar_cmd('git lforvim "%:p"')
  local ll  = ar_cmd('git llforvim "%:p"')
  local lll = ar_cmd('git lllforvim "%:p"')

  -- Note that commands starting with :Git need two carriage returns (<CR>) so that
  -- 'Press ENTER or type command to continue' is not displayed
  utils.nnoremap_silent_bulk({
    -- git blame
    ['<Leader>gb'] = '<Cmd>NormfulGitBlame<CR><F15><CR>',

    -- git commit
    ['<Leader>gw'] = '<Cmd>Git w<CR><CR><CR>',

    ['<Leader>gd'] = quick_look_ar_cmd('git dforvim'),

    -- git diff --cached
    ['<Leader>gdc'] = ar_cmd('git dcforvim'),

    -- git show
    ['<Leader>gsh'] = '<Cmd>Git show<CR><CR>',

    -- git status
    ['<Leader>gs'] = '<Cmd>Git status<CR>',

    -- git log of current file
    ['<Leader>gl'] = l,
    ['<Leader>gll'] = ll,
    ['<Leader>glll'] = lll,
    ['<Leader>l'] = l,
    ['<Leader>ll'] = ll,
    ['<Leader>lll'] = lll,

    -- git contributors to this repo
    ['<Leader>gppl'] = quick_look_ar_cmd('git pplforvim'),
  })
end

configure_git_mappings()
