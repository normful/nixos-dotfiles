local function configure()
  local utils = require('utils')

  local err_msg_cmd = '<Cmd>echoerr "Use [Right Command + e] open file tree explorer"<CR>'

  utils.nnoremap_silent_bulk({
    -- Karabiner Elements maps Command + e => <F17>
    ['<F17>'] = '<Cmd>NvimTreeFindFile<CR>',

    ['<C-e>'] = err_msg_cmd,
    ['E']     = err_msg_cmd,
  })

  local nvim_tree = require('nvim-tree')

  nvim_tree.setup({
    view = {
      width = 50,
      mappings = {
        list = {
          { key = {"<CR>", "o"}, action = 'edit_no_picker' },
          { key = 'u', action = 'dir_up' },

          { key = 'x', action = 'cut' },
          { key = 'c', action = 'copy' },
          { key = 'p', action = 'paste' },

          { key = '<F15>', action = 'close' },
          { key = '<F17>', action = 'close' },

          { key = 'v', action = 'vsplit' },
          { key = 's', action = 'split' },

          { key = '<Tab>', action = 'preview' },

          { key = 'a', action = 'create' },
          { key = 'dd', action = 'remove' },
          { key = 're', action = 'rename' },
        }
      }
    }
  })

  local g = vim.g
  g.nvim_tree_width = 50
  g.nvim_tree_highlight_opened_files = 1
  g.nvim_tree_git_hl = true
  g.nvim_tree_quit_on_open = 1
  g.nvim_tree_disable_window_picker = 1
  g.nvim_tree_show_icons = {
    files   = 0,
    folders = 1,
    git     = 1,
  }

  g.nvim_tree_icons = {
    default = ' ',
    symlink = 's',
    folder = {
      default = '⚧',
      open = '⚩',
      empty = '⚬',
      empty_open = '⚭',
      symlink = '⚮',
      symlink_open = '⚯',
    },
    git = {
      unstaged = '☷',
      staged = '☰',
      unmerged = '☵',
      renamed = '⚏',
      untracked = '⚊',
      deleted = '⚋',
    },
  }
end

return {
  name = 'kyazdani42/nvim-tree.lua',
  configure = configure,
}
