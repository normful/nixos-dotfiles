local blog_output_dir = '/Users/norman/code/blog/content/blog/' 

local function get_blog_markdown_path(lang)
  local filename_template = lang == 'ja' and '%s.ja.md' or '%s.md'
  local markdown_filename = string.format(filename_template, vim.fn.expand('%:t:r'))
  return blog_output_dir .. vim.fn.fnameescape(markdown_filename)
end

local function export_and_edit_markdown(markdown_path)
  vim.cmd(string.format(':Neorg export to-file %s', markdown_path))
  vim.cmd('vsplit ' .. markdown_path)
end

local function is_within_codepoint_range(number, startCodepoint, endCodepoint)
  return number >= startCodepoint and number <= endCodepoint
end

local function is_in_japanese_codepoint_ranges(number)
  local hiraganaStart = 12288
  local katakanaEnd = 12543
  local kanjiStart = 19968
  local kanjiEnd = 40895

  if is_within_codepoint_range(number, hiraganaStart, katakanaEnd) then
    return true
  elseif is_within_codepoint_range(number, kanjiStart, kanjiEnd) then
    return true
  else
    return false
  end
end

local function contains_japanese_chars(str)
  local utf8 = require("utf8")

  for _, char in utf8.codes(str) do
    local codepoint = utf8.codepoint(char, 1, -1)
    if is_in_japanese_codepoint_ranges(codepoint) then
      return true
    end
  end

  return false
end

local function has_japanese_norg_title()
  local first_two_lines = vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), 0, 2, false)
  for idx, line in ipairs(first_two_lines) do
    local is_title_line = idx == 2
    if is_title_line and contains_japanese_chars(line) then
      return true
    end
  end
  return false
end

local function convert_metadata_to_zola_markdown_format()
  vim.cmd([[:2s/^title:/title =/e]])
  vim.cmd([[:3s/^date:/date =/e]])
end

local function find_and_replace_markdown_ext_placeholder(lang)
  local replacement = lang == 'ja' and '.ja.md' or '.md'
  vim.cmd([[:6,$s/\.MARKDOWN_EXT_PLACEHOLDER/]] .. replacement .. [[/ge]])
end

local function save_buffer()
  vim.cmd(':w')
end

local function git_add_and_commit()
  vim.cmd(string.format([[:AsyncRun -cwd=%s -silent git cblog]], blog_output_dir))
end

local function close_other_windows()
  local current_win = vim.api.nvim_get_current_win()
  local other_wins = vim.api.nvim_list_wins()

  local delay_ms = 4000
  vim.defer_fn(function()
    for _, win in ipairs(other_wins) do
      if win ~= current_win then
        vim.api.nvim_win_close(win, true)
      end
    end
  end, delay_ms)
end

local function reformat_links_to_ja_pages_from_english_pages(lang)
  if lang == 'ja' then
    return
  end
  vim.cmd([[:6,$s/\.ja](@/](@/ge]])
end

local function write_blog_markdown(lang)
  local original_win = vim.api.nvim_get_current_win()
  local original_buf = vim.api.nvim_get_current_buf()

  vim.cmd(':Neorg inject-metadata')
  save_buffer()

  export_and_edit_markdown(get_blog_markdown_path(lang))
  convert_metadata_to_zola_markdown_format()
  find_and_replace_markdown_ext_placeholder(lang)
  reformat_links_to_ja_pages_from_english_pages(lang)
  save_buffer()

  git_add_and_commit()

  vim.api.nvim_set_current_win(original_win)
  vim.api.nvim_set_current_buf(original_buf)

  close_other_windows()
end

local function configure_neorg()
  require('neorg').setup({
    load = {
      ['core.esupports.hop'] = {},
      ['core.esupports.indent'] = {},
      ['core.esupports.metagen'] = {},
      ['core.itero'] = {},
      ['core.looking-glass'] = {},
      ['core.pivot'] = {},
      ['core.promo'] = {},
      ['core.qol.todo_items'] = {},
      ['core.keybinds'] = {},
      ['core.dirman'] = {
        config = {
          workspaces = {
            notes = '~/code/notes',
          },
          default_workspace = 'notes',
          autochdir = true,
          index = 'Notes index.norg',
        },
      },
      ['core.journal'] = {
        config = {
          strategy = 'flat',
          journal_folder = '',
          use_template = false,
          workspace = 'notes',
          open_last_workspace = true,
          use_popup = true,
        }
      },
      ['core.concealer'] = {
        config = {
          folds = true,
          icon_preset = 'diamond',
          icons = {
            todo = {
              undone = { icon = ' ' },
              done = { icon = '✔' },
              uncertain = { icon = '?' },
              urgent = { icon = '!' },

              cancelled = { icon = '_' },
              on_hold = { icon = '=' },
              pending = { icon = '-' },
            },
          }
        },
      },
      ['core.esupports.metagen'] = {
        config = {
          -- One of "none", "auto" or "empty"
          -- - "none" generates no metadata
          -- - "auto" generates metadata if it is not present
          -- - "empty" generates metadata only for new files/buffers.
          type = 'empty',

          -- Whether updated date field should be automatically updated on save if required
          update_date = false,

          template = {
            {
              'title',
              function()
                return string.format('"%s"', vim.fn.expand('%:p:t:r'))
              end,
            },
            {
              'date',
              function()
                return os.date('%Y-%m-%d')
              end,
            },
          },

        },
      },
      ['core.export'] = {
        config = {},
      },
      ['core.export.markdown'] = {
        config = {
          extensions = 'all',
          metadata = {
            ['start'] = '+++',
            ['end'] = '+++',
          },
        },
      },
      ['core.summary'] = {},
    },
  })
end

return {
  'normful/neorg',
  dependencies = {
    { 'nvim-lua/plenary.nvim' },
    { 'uga-rosa/utf8.nvim' },
    { 'tpope/vim-fugitive' },
  },
  keys = {
    { '<Leader>ni', '<Cmd>Neorg index<CR>' },
    { '<Leader>ei', '<Cmd>Neorg index<CR>' },
    { '<Leader>en', '<Cmd>Neorg journal today<CR>' },
    { '<Leader>er', '<Cmd>Neorg return<CR>' },

    { '<Leader>nc', '<Cmd>Neorg toggle-concealer<CR>' },

    { '<Leader>mcb', '<Cmd>Neorg keybind all core.looking-glass.magnify-code-block<CR>' },

    { '<Leader>mb', function() write_blog_markdown(has_japanese_norg_title() and 'ja' or 'en') end, desc = 'Export to Markdown blog post' },
  },
  config = configure_neorg,
  lazy = false,
  build = ':Neorg sync-parsers',
}
