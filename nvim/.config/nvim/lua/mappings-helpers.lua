local M = {}

local term = require('nvchad.term')

--- Gets the absolute path to the Git repository root directory
--- containing the file of the current Neovim buffer.
---
--- @return string? The absolute path to the git root, or nil if not found
---                 (e.g., buffer not associated with a file, file not in a git repo,
---                  or git command fails).
M.get_current_buffer_git_root = function()
  -- 1. Get the full file path of the current buffer
  local current_bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(current_bufnr)

  -- 2. Check if the buffer has a file path associated with it
  if filepath == nil or filepath == '' then
    -- Current buffer has no associated file
    return nil
  end

  -- 3. Get the directory containing the file.
  --    ':p' ensures the path is absolute (though buf_get_name usually is).
  --    ':h' gets the head (directory part) of the path.
  local file_dir = vim.fn.fnamemodify(filepath, ':p:h')

  if vim.fn.isdirectory(file_dir) == 0 then
    -- Unlikely if buf_get_name returned a path, but possible in edge cases.
    return nil
  end

  -- 4. Construct the command to find the git root.
  --    'git rev-parse --show-toplevel' finds the root directory.
  --    '-C <dir>' tells git to run as if started in <dir>. This avoids needing
  --               to change Neovim's current directory.
  --    We pass the command parts as a list to vim.fn.systemlist for safer execution
  --    (avoids shell escaping issues compared to concatenating a string).
  local cmd = { 'git', '-C', file_dir, 'rev-parse', '--show-toplevel' }

  -- 5. Execute the command.
  --    vim.fn.systemlist executes the command and captures stdout lines as a list.
  --    We expect only one line of output (the root path).
  --    The second argument `{text = true}` ensures output is treated as text.
  local result_lines = vim.fn.systemlist(cmd)

  -- 6. Check if the command executed successfully.
  --    v:shell_error (vim.v.shell_error in Lua) holds the exit code of the last command.
  --    0 indicates success. Non-zero usually means not a git repo or git failed.
  if vim.v.shell_error ~= 0 then
    -- Not a git repository or 'git' command failed for directory
    return nil
  end

  -- 7. Check if we got any output (should have one line on success)
  if #result_lines == 0 or result_lines[1] == nil or result_lines[1] == '' then
    -- print("Git command succeeded but produced no output.")
    return nil
  end

  -- 8. Return the first line of output (the git root path).
  --    The output from git should already be an absolute path.
  --    vim.fn.systemlist usually doesn't include the trailing newline,
  --    but we can trim just in case.
  return vim.trim(result_lines[1])
end

--- Creates and returns a function that opens a terminal using nvchad.term.
-- The returned function, when called, will execute a command template within
-- a new terminal window positioned at the bottom, vertically split.
-- The command's working directory is set to the git root of the current buffer's file.
--
-- @param terminal_id (string|number) An identifier for the terminal instance (used by nvchad.term).
-- @param cmd_template (string) The command string template to execute.
--                              If it contains 'FILEPATH', this will be replaced by the
--                              absolute path of the current buffer's file.
-- @return function A function that, when called, opens the terminal and runs the command.
M.open_nvchad_term = function(terminal_id, cmd_template)
  return function()
    local expanded_cmd

    if cmd_template:find('FILEPATH') then
      -- vim.fn.expand('%:p') gets the full path (:p) of the current file (%)
      expanded_cmd = string.gsub(cmd_template, 'FILEPATH', vim.fn.expand('%:p'))
    else
      -- If '%s' is not found, use the command template directly.
      expanded_cmd = cmd_template
    end

    -- Call the runner function from the nvchad.term module to open and run the command.
    term.runner({
      -- Identifier for the terminal session.
      id = terminal_id,

      cmd = expanded_cmd,

      -- Position of the terminal window: 'bo' (bottom), 'vsp' (vertical split).
      pos = 'bo vsp',

      -- Relative size of the terminal window (e.g., 70% of the available height/width).
      size = 0.7,

      -- Options passed directly to the underlying terminal opening function vim.fn.termopen.
      -- See :h jobstart-options for other potential options here.
      termopen_opts = {
        -- Set the current working directory for the command run inside the terminal
        -- as the git repository root folder containing the current buffer's file.
        cwd = M.get_current_buffer_git_root(),
        clear_env = true,
      },
    })
  end
end

return M
