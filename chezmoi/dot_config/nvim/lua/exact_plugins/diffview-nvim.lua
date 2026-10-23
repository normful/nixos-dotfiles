-- Copied from https://github.com/richardgill/nix/blob/ebdd8260f770d242db7b6163158cfe9ad9784c41/modules/home-manager/dot-files/nvim/lua/plugins/git-diff_diffview.lua
-- See https://richardgill.org/blog/configuring-neovim-coding-agents

local is_git_ignored = function(filepath)
  vim.fn.system('git check-ignore -q ' .. vim.fn.shellescape(filepath))
  return vim.v.shell_error == 0
end

local update_left_pane = function()
  pcall(function()
    local lib = require('diffview.lib')
    local view = lib.get_current_view()
    if view then
      -- This updates the left panel with all the files, but doesn't update the buffers
      view:update_files()
    end
  end)
end

-- Register handler for file changes in watched directory
--
-- Maybe functionality in https://github.com/greggh/claude-code.nvim might replace this?
require('directory-watcher').registerOnChangeHandler('diffview', function(filepath, _events)
  local is_in_dot_git_dir = filepath:match('/%.git/') or filepath:match('^%.git/')

  if is_in_dot_git_dir or not is_git_ignored(filepath) then
    vim.notify('[diffview] File changed: ' .. vim.fn.fnamemodify(filepath, ':t'), vim.log.levels.INFO)
    update_left_pane()
  end
end)

vim.api.nvim_create_autocmd('FocusGained', {
  callback = update_left_pane,
})

vim.api.nvim_create_autocmd('User', {
  pattern = 'DiffviewViewLeave',
  callback = function()
    vim.cmd(':DiffviewClose')
  end,
})

return {
  'sindrets/diffview.nvim',
  lazy = false,
  config = function()
    require('diffview').setup({
      default_args = {
        DiffviewOpen = { '--imply-local' },
      },
      keymaps = {
        view = {
          { 'n', 'q', '<Cmd>DiffviewClose<CR>', { desc = 'Close diffview' } },
        },
        file_panel = {
          { 'n', 'q', '<Cmd>DiffviewClose<CR>', { desc = 'Close diffview' } },
        },
        file_history_panel = {
          { 'n', 'q', '<Cmd>DiffviewClose<CR>', { desc = 'Close diffview' } },
        },
      },
    })
  end,
}
