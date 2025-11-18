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
      cmp = true,

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

      -- transform_implicit is called by mkdnflow immediately before interpreting a link path.
      -- This transform_implicit function was added so that the NORMAL mode's <CR> mapping that
      -- calls MkdnEnter will open the correct file, when the filename has URL encoded characters
      -- in the Markdown link path text.
      --
      -- This transforms the link path text without modifying the actual buffer content.
      -- Use case: Decode URL-encoded paths like "a%20b.md" → "a b.md" before opening the file.
      --
      -- How URL encoding works:
      --   Special characters are encoded as %XX where XX is the hexadecimal ASCII code
      --   Examples: space → %20, "/" → %2F, ":" → %3A
      transform_implicit = function(link_path_text)
        -- Apply URL decoding to the link path text before mkdnflow interprets it
        -- This allows markdown links like [text](a%20b.md) to correctly open "a b.md"
        local decoded_path = url_decode_string(link_path_text)
        return decoded_path
      end,

      transform_explicit = function(square_bracketed_text)
        local kindle_title_author_separator = ' - '
        -- Use plain search (4th argument = true) to avoid interpreting '-' as a pattern
        local sep_idx = string.find(square_bracketed_text, kindle_title_author_separator, 1, true)
        local is_kindle_highlights_markdown_file = sep_idx and sep_idx > 1

        if is_kindle_highlights_markdown_file then
          return square_bracketed_text
        end

        local charset = 'abcdefghijklmnopqrstuvwxyz0123456789'
        local result = ''
        for _ = 1, 8 do
          local index = math.random(1, #charset)
          result = result .. charset:sub(index, index)
        end
        return result
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

      -- MkdnTagSpan = { 'v', '<Leader>ts' },

      -- These didn't work for me
      -- MkdnYankAnchorLink = { 'n', '<Leader>zh' },
      -- MkdnYankFileAnchorLink = { 'n', '<Leader>zy' },

      --[[ MkdnTableNextCell = { 'i', '<Tab>' },
      MkdnTablePrevCell = { 'i', '<S-Tab>' },
      MkdnTableNextRow = false,
      MkdnTablePrevRow = { 'i', '<M-CR>' },
      MkdnTableNewRowBelow = { 'n', '<leader>ir' },
      MkdnTableNewRowAbove = { 'n', '<leader>iR' },
      MkdnTableNewColAfter = { 'n', '<leader>ic' },
      MkdnTableNewColBefore = { 'n', '<leader>iC' }, ]]
    },
    new_file_template = {
      use_template = true,
      placeholders = {
        before = {
          day_of_week = function()
            return os.date('%A')
          end,
          iso_8601_date = function()
            local t = os.time()
            local offset = os.date('%z', t)
            return os.date('%Y-%m-%dT%H:%M:%S', t) .. offset
          end,
        },
      },
      template = [[
---
title: {{ title }}
day: {{ day_of_week }}
date: {{ iso_8601_date }}
author:
    - Norman Sue
tags: []
aliases: []
---

# References
]],
    },
    perspective = {
      priority = 'root',
      root_tell = '.git',
    },

    -- Should keep aligned with the custom checkboxes configured in
    -- MeanderingProgrammer/render-markdown.nvim config.
    to_do = {
      symbols = { ' ', '.', '!', '?', '+', '=', 'x' },
      not_started = ' ',
      in_progress = '.',
      complete = 'x',
      update_parents = true,
    },
  })
end

return {
  'jakewvincent/mkdnflow.nvim',
  lazy = false,
  config = configure_mkdnflow_nvim,
}
