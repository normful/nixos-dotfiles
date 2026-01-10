-- Copied from https://github.com/richardgill/nix/blob/975f6e9031b35df11d6cf0f100e3106c985cb594/modules/home-manager/dot-files/nvim/lua/custom/hotreload.lua
-- See https://richardgill.org/blog/configuring-neovim-coding-agents

local M = {}

local function should_check()
  local ok, mode = pcall(vim.api.nvim_get_mode)
  if not ok then return false end
  
  return not (
    mode.mode:match('[cR!s]') -- Skip: command-line, replace, ex, select modes
    or vim.fn.getcmdwintype() ~= '' -- Skip: command-line window is open
  )
end

local function should_reload_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return false end

  local ok_name, name = pcall(vim.api.nvim_buf_get_name, buf)
  local ok_bt, buftype = pcall(vim.api.nvim_get_option_value, 'buftype', { buf = buf })
  local ok_mod, modified = pcall(vim.api.nvim_get_option_value, 'modified', { buf = buf })

  if not (ok_name and ok_bt and ok_mod) then return false end

  local is_real_file = name ~= '' and not name:match('^%w+://') -- Skip URIs like diffview://, fugitive://, etc

  return is_real_file and buftype == '' and not modified
end

local function get_visible_buffers()
  local visible = {}
  local ok_wins, wins = pcall(vim.api.nvim_list_wins)
  if not ok_wins then return visible end

  for _, win in ipairs(wins) do
    if vim.api.nvim_win_is_valid(win) then
      local ok_buf, buf = pcall(vim.api.nvim_win_get_buf, win)
      if ok_buf then
        visible[buf] = true
      end
    end
  end
  return visible
end

local find_buffer_by_filepath = function(filepath)
  local visible_buffers = get_visible_buffers()
  for buf, _ in pairs(visible_buffers) do
    local ok, name = pcall(vim.api.nvim_buf_get_name, buf)
    if ok and name == filepath then
      return buf
    end
  end
  return nil
end

-- Register handler for file changes in watched directory
require('directory-watcher').registerOnChangeHandler('hotreload', function(filepath, _events)
  if not should_check() then
    return
  end

  local buf = find_buffer_by_filepath(filepath)
  if buf and should_reload_buffer(buf) then
    pcall(vim.cmd, 'checktime ' .. buf)
  end
end)

M.setup = function(_opts)
  vim.api.nvim_create_autocmd({ 'FocusGained', 'TermLeave', 'BufEnter', 'WinEnter', 'CursorHold', 'CursorHoldI' }, {
    group = vim.api.nvim_create_augroup('hotreload', { clear = true }),
    callback = function()
      if should_check() then
        pcall(vim.cmd, 'checktime')
      end
    end,
  })
end

return M
