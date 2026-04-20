-- Replacement function that converts each %XX URL-encoded sequence to its actual character
-- This is called by url_decode_string for each %XX pattern match
local function decode_hex_sequence(hex_digits)
  -- hex_digits is a 2-character string like "20", "2F", "3A"
  -- captured by the (%x%x) group in the pattern

  -- Step 1: Convert hex string to decimal number
  -- tonumber(string, base) converts a string to a number using the specified base
  -- Base 16 means hexadecimal (0-9, A-F)
  -- Examples:
  --   tonumber("20", 16) → 32  (hex 20 = decimal 32 = ASCII space)
  --   tonumber("2F", 16) → 47  (hex 2F = decimal 47 = ASCII forward slash)
  --   tonumber("3A", 16) → 58  (hex 3A = decimal 58 = ASCII colon)
  local ascii_code = tonumber(hex_digits, 16)

  -- Step 2: Convert the ASCII code to its corresponding character
  -- string.char(number) returns the character with that ASCII code
  -- Examples:
  --   string.char(32)  → " "  (space)
  --   string.char(47)  → "/"  (forward slash)
  --   string.char(58)  → ":"  (colon)
  local decoded_character = string.char(ascii_code)

  return decoded_character
end

-- Helper function to perform URL decoding on a string
-- Converts URL-encoded characters like %20 → space, %2F → /, etc.
local function url_decode_string(encoded_string)
  -- Pattern to match URL-encoded sequences like %20, %2F, %3A, etc.
  -- '%%(%x%x)' breaks down as:
  --   %%     - A literal percent sign (% must be escaped as %% in Lua patterns)
  --   (...)  - Capture group to extract what's inside for use in replacement
  --   %x     - Matches one hexadecimal digit (0-9, a-f, A-F)
  --   %x     - Matches a second hexadecimal digit
  -- So this pattern matches: %20, %2F, %3A, %C3, %A9, etc.
  local url_encoded_pattern = '%%(%x%x)'

  -- string.gsub performs global substitution (find and replace all occurrences)
  -- Syntax: string.gsub(input_string, pattern, replacement_function)
  -- It finds all matches of url_encoded_pattern and replaces each with the result
  -- of calling decode_hex_sequence with the captured hex digits
  --
  -- Example transformation:
  --   Input:  "my%20file%2Fname.md"
  --   Step 1: Finds "%20" → decode_hex_sequence("20") → " "
  --   Step 2: Finds "%2F" → decode_hex_sequence("2F") → "/"
  --   Output: "my file/name.md"
  local decoded_string = string.gsub(encoded_string, url_encoded_pattern, decode_hex_sequence)

  return decoded_string
end

local function random_eight_chars_note_id()
  local charset = 'abcdefghijklmnopqrstuvwxyz0123456789'
  local result = ''
  for _ = 1, 8 do
    local index = math.random(1, #charset)
    result = result .. charset:sub(index, index)
  end
  return result
end

local function dont_propagate_down()
  return nil
end

local function configure_mkdnflow_nvim()
  require('mkdnflow').setup({
    modules = {
      maps = true,
      tables = true,
      buffers = true,
      cursor = true,
      links = true,
      lists = true,
      paths = true,
      to_do = true,
      completion = true,
      notebook = true,

      bib = false,
      conceal = false,
      yaml = false,

      -- Tried these but they didn't work well.
      -- I use MeanderingProgrammer/render-markdown.nvim instead.
      folds = false,
      foldtext = false,
    },
    links = {
      style = 'markdown',
      search_range = 2,

      -- transform_on_follow is called by mkdnflow immediately before interpreting a link path.
      -- This transform_on_follow function was added so that the NORMAL mode's <CR> mapping that
      -- calls MkdnEnter will open the correct file, when the filename has URL encoded characters
      -- in the Markdown link path text.
      --
      -- This transforms the link path text without modifying the actual buffer content.
      -- Use case: Decode URL-encoded paths like "a%20b.md" → "a b.md" before opening the file.
      --
      -- How URL encoding works:
      --   Special characters are encoded as %XX where XX is the hexadecimal ASCII code
      --   Examples: space → %20, "/" → %2F, ":" → %3A
      transform_on_follow = function(link_path_text)
        -- Apply URL decoding to the link path text before mkdnflow interprets it
        -- This allows markdown links like [text](a%20b.md) to correctly open "a b.md"
        local decoded_path = url_decode_string(link_path_text)
        return decoded_path
      end,

      -- transforms the text to be inserted as the source/path of a link when a link is created
      transform_on_create = function(link_source_path_text)
        local kindle_title_author_separator = ' - '
        local sep_idx = string.find(link_source_path_text, kindle_title_author_separator, 1, true) -- Use plain search (4th argument = true) to avoid interpreting '-' as a pattern
        local is_kindle_highlights_markdown_file = sep_idx and sep_idx > 1

        if is_kindle_highlights_markdown_file then
          return link_source_path_text
        end

        return random_eight_chars_note_id()
      end,

      on_create_new = function(path, title)
        local cmd = {
          'zk',
          'new',
          '--no-input',
          '--print-path',

          '--working-dir',
          vim.fn.expand('~/code/alcove'),

          '--id',
          vim.fn.fnamemodify(path, ':t:r'),
        }

        if title then
          table.insert(cmd, '--title')
          table.insert(cmd, title)
        end

        local cmd_result = vim.fn.system(cmd)
        if vim.v.shell_error ~= 0 then
          vim.notify('mkdnflow on_create_new: zk new failed: ' .. cmd_result, vim.log.levels.ERROR)
          return nil
        end

        local new_path = vim.trim(cmd_result)
        return new_path -- mkdnflow opens the zk-created file
      end,
    },
    mappings = {
      MkdnEnter = { { 'n', 'v' }, '<CR>' },

      -- Instead of MkdnCreateLinkFromClipboard, I'm using a custom user command
      -- NormfulInsertLink that wraps MkdnCreateLinkFromClipboard amongst others

      MkdnGoBack = { 'n', '[[' },
      MkdnGoForward = { 'n', ']]' },

      MkdnNewListItem = { 'i', '<CR>' },
      MkdnNewListItemBelowInsert = { 'n', 'o' },
      MkdnNewListItemAboveInsert = { 'n', 'O' },

      MkdnIncreaseHeading = { 'n', '-' },
      MkdnDecreaseHeading = { 'n', '+' },

      MkdnUpdateNumbering = { 'n', '<Leader>rn' },

      MkdnToggleToDo = { { 'n', 'v' }, '<C-Space>' },
    },

    perspective = {
      priority = 'root',
      root_tell = '.git',
    },

    to_do = {
      highlight = false,

      -- Keep these custom statuses aligned with the custom checkboxes configured for
      -- MeanderingProgrammer/render-markdown.nvim
      statuses = {
        not_started = {
          marker = ' ',
          down = function(child_list)
            local target_statuses = {}
            for _ = 1, #child_list.items, 1 do
              table.insert(target_statuses, 'not_started')
            end
            return target_statuses
          end,
        },
        in_progress = {
          marker = '.',
          propagate = {
            down = dont_propagate_down,
          },
        },
        urgent = {
          marker = '!',
          propagate = {
            down = function(child_list)
              local target_statuses = {}
              for _ = 1, #child_list.items, 1 do
                table.insert(target_statuses, 'urgent')
              end
              return target_statuses
            end,
          },
        },
        uncertain = {
          marker = '?',
          propagate = {
            down = function(child_list)
              local target_statuses = {}
              for _ = 1, #child_list.items, 1 do
                table.insert(target_statuses, 'uncertain')
              end
              return target_statuses
            end,
          },
        },
        repeating = {
          marker = '+',
          propagate = {
            down = function(child_list)
              local target_statuses = {}
              for _ = 1, #child_list.items, 1 do
                table.insert(target_statuses, 'repeating')
              end
              return target_statuses
            end,
          },
        },
        stopped = {
          marker = '=',
          propagate = {
            down = dont_propagate_down,
          },
        },
        complete = {
          marker = 'x',
          propagate = {
            down = function(child_list)
              local target_statuses = {}
              for _ = 1, #child_list.items, 1 do
                table.insert(target_statuses, 'complete')
              end
              return target_statuses
            end,
          },
        },
      },
      status_propagation = {
        up = false,
        down = true,
      },
      -- A status defined in to_do.statuses but absent from status_order is
      -- still recognized when reading files, but excluded from toggle rotation.
      status_order = {
        'not_started',
        'in_progress',
        'stopped',
        'complete',
      },
      sort = {
        on_status_change = false,
        recursive = false,
        cursor_behavior = {
          track = true,
        },
      },
    },
  })
end

return {
  'jakewvincent/mkdnflow.nvim',
  lazy = false,
  config = configure_mkdnflow_nvim,
  keys = {
    {
      '<Leader>zl',
      '0vg_<Cmd>MkdnEnter<CR>',
      mode = 'n',
      buffer = true,
      desc = 'Create line link to new note',
    },
  },
}
