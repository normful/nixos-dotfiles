local function add_general_maps()
  local g = vim.g
  local utils = require("utils")

  -- Leader keys
  g.mapleader = ","
  g.maplocalleader = "\\"

  local disable_arrow_keys = {
    ['<Up>']    = '<Cmd>echoerr "Use k instead"<CR>',
    ['<Down>']  = '<Cmd>echoerr "Use j instead"<CR>',
    ['<Left>']  = '<Cmd>echoerr "Use h instead"<CR>',
    ['<Right>'] = '<Cmd>echoerr "Use l instead"<CR>',
  }

  utils.nnoremap_silent_bulk(disable_arrow_keys)
  utils.inoremap_silent_bulk(disable_arrow_keys)

  utils.xnoremap_silent_bulk({
    -- Visual shifting (does not exit Visual mode)
    ['<'] = '<gv',
    ['>'] = '>gv',

    -- Navigating wrapped lines
    ['j'] = 'gj',
    ['k'] = 'gk',
    ['^'] = 'g^',
    ['0'] = 'g0',
    ['$'] = 'g$',
  })

  utils.cnoremap_silent_bulk({
    ['<c-j>'] = '<Down>',
    ['<c-k>'] = '<Up>',
    ['<c-h>'] = '<S-left>',
    ['<c-l>'] = '<S-right>',

    -- Allow saving of files as sudo after forgetting to start vim with sudo
    -- https://stackoverflow.com/a/58215799
    ['w!!'] = 'execute "silent! write !SUDO_ASKPASS=`which ssh-askpass` sudo tee % >/dev/null" <bar> edit!',
  })

  utils.tnoremap_silent_bulk({
    -- Enter NORMAL mode
    -- Many people on the internet map this to <Esc>. However, this is purposely not mapped to <Esc>, in
    -- order to avoid having <Esc> interfere with Zsh's vi mode. i.e. <Esc> exit out of Zsh's vi insert mode,
    -- but still be in nvim's TERMINAL mode.
    ['<Leader><Esc>'] = '<C-\\><C-n>',

    -- Enter NORMAL mode and switch window
    ['<C-w>'] = '<C-\\><C-n><C-w>w',
  })

  utils.nnoremap_silent_bulk({
    -- Quick file editing
    -- TODO(norman): Re-enable with new paths later
    -- ['<Leader>ev'] = '<Cmd>100vsplit ~/code/nixos-dotfiles/nvim/nvim.nix<CR>',
    -- ['<Leader>es'] = '<Cmd>100vsplit ~/code/nixos-dotfiles/nvim/lua/general_settings.lua<CR>',
    -- ['<Leader>em'] = '<Cmd>100vsplit ~/code/nixos-dotfiles/nvim/lua/general_maps.lua<CR>',

    ['<Leader>em'] = '<Cmd>100vsplit ~/code/nixos-dotfiles/macbook-pro-18-3-config.nix<CR>',
    ['<Leader>eg'] = '<Cmd>100vsplit ~/code/nixos-dotfiles/git/.gitconfig<CR>',
    ['<Leader>ek'] = '<Cmd>100vsplit ~/code/nixos-dotfiles/kitty/.config/kitty/kitty.conf<CR>',
    ['<Leader>ef'] = '<Cmd>100vsplit ~/code/nixos-dotfiles/fish/.config/fish/config.fish<CR>',

    ['Y'] = 'yy',

    ['D'] = '<Cmd>echoerr "Use [Right Command + j/d] to scroll down"<CR>', -- Avoid right-pinky RSI. D is usually: Delete the rest of the line from the cursor
    ['U'] = '<Cmd>echoerr "Use [Right Command + k/u] to scroll up"<CR>', -- Avoid right-pinky RSI. U is usually: Undo the line

    ['<C-d>'] = '<Cmd>echoerr "Use [Right Command + j/d] to scroll down"<CR>', -- Avoid left-pinky RSI.
    ['<C-u>'] = '<Cmd>echoerr "Use [Right Command + k/u] to scroll up"<CR>', -- Avoid left-pinky RSI.

    -- Karabiner Elements maps Command + j => <F13>
    -- Karabiner Elements maps Command + d => <F13>
    ['<F13>'] = '20j',

    -- Karabiner Elements maps Command + k => <F14>
    -- Karabiner Elements maps Command + u => <F14>
    ['<F14>'] = '20k',

    -- Disable accidental entering of command-line mode
    -- (i.e. entering `:       `)
    ['Q'] = '<Cmd>echoerr "Q enters command-line mode usually, but has been disabled"<CR>',

    -- Note: q: in NORMAL mode opens the command-line _history_

    -- Quickfix
    ['<Down>'] = '<Cmd>cnext<CR>',
    ['<Up>'] = '<Cmd>cprevious<CR>',
    -- :cw[indow] Open the quickfix window when there are recognized errors.

    -- Location list
    --   A location list is a window-local quickfix list.
    --   A location list is associated with a window and each window can have a separate location list.
    --   A location list can be associated with only one window.
    --   The location list is independent of the quickfix list.
    --   When a window with a location list is split, the new window gets a copy of the location list.
    --   When there are no longer any references to a location list, the location list is destroyed.
    ['<C-S-j>'] = '<Cmd>lnext<CR>',
    ['<C-S-k>'] = '<Cmd>lprevious<CR>',
    -- :lopen    Open a window to show the location list for the current window.
    -- :lclose

    -- Window cycling
    -- Karabiner Elements maps Command + w => <F15>
    ['<F15>'] = '<C-w>w',
    -- ['<C-w>'] = '<Cmd>echoerr "Use [Right Command + w] to window cycle"<CR>', -- Avoid left-pinky RSI

    -- Window closing
    -- Karabiner Elements maps Command + q => <F18>
    ['<F18>'] = '<Cmd>close<CR>',

    -- Buffer navigation
    --   Use Telescope's <Leader>b

    -- Buffer cycling in the current window
    -- +--------------------------+
    -- |current window|   buf no. |
    -- |1234567...    |     27    |
    -- | --->         | unchanged |
    -- |--------------|           |
    -- | 61 unchanged |           |
    -- +--------------------------+
    -- Karabiner Elements maps Command + h => <F16>
    ['<F16>'] = '<Cmd>bnext<CR>',

    -- Search with ERE regex, not vim's default 'magic' regex
    ['/'] = '/\\v',

    -- Horizontal scrolling
    ['zl'] = 'zL',
    ['zh'] = 'zH',

    -- Toggle search highlight
    ['<Localleader>h'] = '<Cmd>set hlsearch!<CR>',

    -- Toggle wrap
    ['<Localleader>w'] = '<Cmd>set wrap!<CR>',

    -- Strip trailing white space
    ['<Localleader>s'] = ':call StripTrailingWhitespace()<CR>',

    -- Set tab settings
    ['<Localleader><Tab>'] = ':call normful#SetTabSettings()<CR>',

    -- Switch all omen windows to horizontal split
    ['<Localleader>H'] = '<Cmd>windo wincmd K<CR>',

    -- Switch all open windows to vertical split
    ['<Localleader>V'] = '<Cmd>windo wincmd H<CR>',
  })
end

add_general_maps()
