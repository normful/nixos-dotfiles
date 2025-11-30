-- General user-defined commands (aka Ex commands or colon commands)
-- See :help user-commands
vim.cmd([[command! -nargs=1 -range SuperRetab <line1>,<line2>s/\v%(^ *)@<= {<args>}/\t/g]])
vim.cmd([[command! -range Listfy <line1>,<line2>s/^\(\s*\)\(\w\+.*\)/\1- [ ] \2/g]])
vim.cmd([[command! -range Bulletfy <line1>,<line2>s/^\(\s*\)-\s\(\w\+.*\)/\1- [ ] \2/g]])
vim.cmd([[command! -range=% WordFrequency <line1>,<line2>call normful#WordFrequency()]])
vim.cmd([[command! NormfulGitBlame call normful#GitBlame()]])

local term_id = 'my_toggle_term'
vim.api.nvim_create_user_command('ToggleNvchadTerminal', function()
  local term = require('nvchad.term')
  local helpers = require('mappings-helpers')
  term.toggle({
    id = term_id,
    pos = 'sp',
    -- Options passed directly to the underlying terminal opening function vim.fn.termopen.
    -- See :h jobstart-options for other potential options here.
    termopen_opts = {
      cwd = helpers.get_current_buffer_git_root(),
      clear_env = true,
    },
  })
end, {
  nargs = 0,
  desc = 'Toggle term in hsplit',
})

vim.api.nvim_create_user_command('MakeItalic', function()
  local keys = vim.api.nvim_replace_termcodes('ciw*<C-r>"*<esc>b', true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', true)
end, { nargs = 0 })

vim.api.nvim_create_user_command('MakeBold', function()
  local keys = vim.api.nvim_replace_termcodes('ciw**<C-r>"**<esc>bb', true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', true)
end, { nargs = 0 })

-- Inserts links from clipboard or creates new Zk links
-- Handles both normal and visual mode
vim.api.nvim_create_user_command('NormfulInsertLink', function(opts)
  if vim.fn.exists(':ZkInsertLink') ~= 2 then
    error('Command not available: ZkInsertLink')
  end

  if vim.fn.exists(':ZkInsertLinkAtSelection') ~= 2 then
    error('Command not available: ZkInsertLinkAtSelection')
  end

  -- Detect if we're in visual mode
  local mode = vim.api.nvim_get_mode().mode
  local in_visual_mode = mode == 'v' or mode == 'V' or mode == '\22' -- \22 is Ctrl-V (visual block)

  -- Get clipboard content and define URL pattern for validation
  local clipboard = vim.fn.getreg('+')
  local url_pattern = '^https?://[^%s]+$'

  -- Check if clipboard contains a valid URL
  -- Invalid if: empty, too long, contains control chars, or doesn't match URL pattern
  if
    not clipboard
    or clipboard == ''
    or #clipboard > 2000
    or string.match(clipboard, '[%z\1-\31\127-\255]')
    or not string.match(clipboard, url_pattern)
  then
    -- No valid URL in clipboard: use Zk commands to create/select links
    if in_visual_mode then
      -- Visual selection: exit visual mode first, then call ZkInsertLinkAtSelection
      -- The '< and '> marks will be preserved and used by get_lsp_location_from_selection()
      -- We MUST exit visual mode because zk's get_lsp_location_from_selection() expects
      -- to be called from normal mode with '< and '> marks from a previous selection
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
      vim.schedule(function()
        require('zk.commands').get('ZkInsertLinkAtSelection')()
      end)
    else
      -- No visual selection: use ZkInsertLink for interactive link creation
      vim.cmd('ZkInsertLink')
    end
    return
  end

  if vim.fn.exists(':MkdnCreateLinkFromClipboard') ~= 2 then
    error('Command not available: MkdnCreateLinkFromClipboard')
  end

  -- Valid URL in clipboard: use mkdnflow for link insertion
  -- Call without range to let mkdnflow handle visual mode directly
  vim.cmd('MkdnCreateLinkFromClipboard')

  -- Clear clipboard after successful link creation to prevent reuse
  vim.fn.setreg('+', '')
end, {
  nargs = 0,
  -- Note: range not needed since we use <Cmd> mapping which keeps visual mode active
})

local function clean_text(text, word)
  -- Remove romaji annotations and unwanted brackets
  text = text:gsub('%[ローマ字%]%([^)]+%)', ''):gsub('┏', ''):gsub('┓', '')
  -- Highlight the word if provided
  if word then
    text = text:gsub(word, '[' .. word .. ']')
  end
  -- Replace circled numbers only at the start of lines
  local lines = vim.split(text, '\n')
  for i, line in ipairs(lines) do
    line = line
      :gsub('^①', '1. ')
      :gsub('^②', '2. ')
      :gsub('^③', '3. ')
      :gsub('^④', '4. ')
      :gsub('^⑤', '5. ')
      :gsub('^⑥', '6. ')
      :gsub('^⑦', '7. ')
      :gsub('^⑧', '8. ')
      :gsub('^⑨', '9. ')
      :gsub('^⑩', '10. ')
    lines[i] = line
  end
  return table.concat(lines, '\n')
end

local function flatten_structured_content(content, word)
  if type(content) == 'string' then
    return clean_text(content, word)
  elseif type(content) == 'table' then
    local result = ''
    for _, item in ipairs(content) do
      if type(item) == 'string' then
        result = result .. clean_text(item, word)
      elseif item.tag == 'span' then
        local wrapped = flatten_structured_content(item.content, word)
        if item.style then
          if item.style.fontWeight == 'bold' then
            wrapped = '**' .. wrapped .. '**'
          elseif item.style.fontSize == '70%' or item.style.fontSize == 'small' then
            wrapped = '*' .. wrapped .. '*'
          elseif item.style.verticalAlign == 'super' then
            wrapped = '^' .. wrapped .. '^' -- Simple superscript marker
          end
        end
        result = result .. wrapped
      elseif item.tag == 'ul' then
        -- Collect li items
        local items = {}
        for _, sub_item in ipairs(item.content or {}) do
          if sub_item.tag == 'li' then
            table.insert(items, { content = flatten_structured_content(sub_item.content, word), style = sub_item.style })
          end
        end
        -- Group into pairs: main (◆) + translation (70% font)
        local ul_result = ''
        local i = 1
        while i <= #items do
          local main = items[i]
          local trans = items[i + 1]
          if
            main
            and trans
            and main.style
            and main.style.listStyleType == "'◆'"
            and trans.style
            and trans.style.fontSize == '70%'
          then
            ul_result = ul_result .. '- ' .. main.content .. ': ' .. trans.content .. '\n'
            i = i + 2
          else
            ul_result = ul_result .. '- ' .. (main and main.content or '') .. '\n'
            i = i + 1
          end
        end
        result = result .. ul_result
      elseif item.tag == 'li' then
        local bullet = '- '
        if item.style and item.style.listStyleType and item.style.listStyleType ~= 'none' then
          -- Remove quotes if present, e.g., "'◆'" -> "◆"
          local style_type = item.style.listStyleType:gsub("^'(.*)'$", '%1')
          bullet = style_type .. ' '
        end
        result = result .. bullet .. flatten_structured_content(item.content, word) .. '\n'
      elseif item.content then
        result = result .. flatten_structured_content(item.content, word)
      end
    end
    return result
  end
  return ''
end

local function format_definition(def, word)
  local entry_text = ''
  if type(def.entries) == 'table' then
    for _, e in ipairs(def.entries) do
      if type(e) == 'string' then
        entry_text = entry_text .. clean_text(e, word) .. '\n'
      elseif type(e) == 'table' and e.type == 'structured-content' then
        entry_text = entry_text .. flatten_structured_content(e.content, word) .. '\n'
      end
    end
  elseif type(def.entries) == 'string' then
    entry_text = clean_text(def.entries, word)
  end
  if entry_text:gsub('%s', '') == '' then
    return nil
  end
  local lines = { '> [!example] ' .. (def.dictionary or 'Unknown Dictionary') }
  for line in entry_text:gmatch('[^\n]+') do
    table.insert(lines, '> ' .. line)
  end
  table.insert(lines, '')
  return lines
end

local function format_entry(entry, word)
  local lines = {}
  if not entry.headwords or #entry.headwords == 0 then
    return lines
  end
  -- Build frequency map by headwordIndex
  local freq_by_hw = {}
  if entry.frequencies then
    for _, f in ipairs(entry.frequencies) do
      if f.headwordIndex and f.frequency then
        freq_by_hw[f.headwordIndex] = freq_by_hw[f.headwordIndex] or {}
        table.insert(freq_by_hw[f.headwordIndex], f.frequency)
      end
    end
  end
  local function get_thermometer(freq)
    if freq <= 2000 then
      return '🟦'
    elseif freq <= 5000 then
      return '🟩🟩'
    elseif freq <= 10000 then
      return '🟨🟨🟨'
    elseif freq <= 20000 then
      return '🟧🟧🟧🟧'
    else
      return '🟥🟥🟥🟥🟥'
    end
  end
  local headwords_text = {}
  for _, hw in ipairs(entry.headwords) do
    local thermo = ''
    if freq_by_hw[hw.index] then
      local min_freq = math.huge
      for _, freq in ipairs(freq_by_hw[hw.index]) do
        if freq < min_freq then
          min_freq = freq
        end
      end
      thermo = ' ' .. get_thermometer(min_freq)
    end
    table.insert(headwords_text, hw.term .. ' (' .. (hw.reading or '') .. ')' .. thermo)
  end
  table.insert(lines, '# ' .. table.concat(headwords_text, ', '))
  table.insert(lines, '')
  -- Sort definitions by score descending
  local sorted_defs = {}
  for _, def in ipairs(entry.definitions or {}) do
    if def.isPrimary then
      table.insert(sorted_defs, def)
    end
  end
  table.sort(sorted_defs, function(a, b)
    return (a.dictionaryIndex or 0) < (b.dictionaryIndex or 0)
  end)
  for _, def in ipairs(sorted_defs) do
    local def_lines = format_definition(def, word)
    if def_lines then
      for _, line in ipairs(def_lines) do
        table.insert(lines, line)
      end
    end
  end
  return lines
end

vim.api.nvim_create_user_command('LookupYomitanDefinitions', function()
  local word = vim.fn.expand('<cword>')
  if word == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return
  end
  local async = require('plenary.async')
  async.void(function()
    local response = require('plenary.curl').post('http://127.0.0.1:19633/termEntries', {
      body = vim.json.encode({ term = word }),
      headers = { ['Content-Type'] = 'application/json' },
    })
    vim.schedule(function()
      if response.status ~= 200 then
        vim.notify('Lookup failed: ' .. tostring(response.status), vim.log.levels.ERROR)
        return
      end
      local data = vim.json.decode(response.body)
      local lines = {}
      if data and data.dictionaryEntries then
        for _, entry in ipairs(data.dictionaryEntries) do
          if entry.isPrimary then
            local entry_word = entry.headwords and entry.headwords[1] and entry.headwords[1].term or word
            local entry_lines = format_entry(entry, entry_word)
            for _, line in ipairs(entry_lines) do
              table.insert(lines, line)
            end
          end
        end
      else
        -- Fallback to beautified JSON
        local pretty_json = vim.fn.system('jq .', response.body or 'No response body')
        if vim.v.shell_error == 0 then
          lines = vim.split(pretty_json, '\n')
        else
          lines = vim.split(response.body or 'No response body', '\n')
        end
      end
      -- Determine popup size based on nesting level
      local is_floating = vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative ~= ''
      if not is_floating then
        vim.g.yomitan_lookup_level = 1
      else
        vim.g.yomitan_lookup_level = (vim.g.yomitan_lookup_level or 1) + 1
      end
      local size_factor = ({ 0.95, 0.90, 0.85, 0.80, 0.75, 0.70, 0.65, 0.60 })[vim.g.yomitan_lookup_level] or 0.60
      -- Open popup
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')

      -- TODO: Fix the bug with this when there are multiple popups open. It should close from highest to lowest
      vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<Cmd>close<CR>', { noremap = true, silent = true })

      local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = math.floor(vim.o.columns * size_factor),
        height = math.floor(vim.o.lines * size_factor),
        col = math.floor(vim.o.columns * (1 - size_factor) / 2),
        row = math.floor(vim.o.lines * (1 - size_factor) / 2),
        style = 'minimal',
        border = 'rounded',
      })
      vim.api.nvim_win_set_option(win, 'wrap', true)
      vim.api.nvim_win_set_option(win, 'foldenable', true)
      vim.api.nvim_win_set_option(win, 'foldmethod', 'indent')
      vim.api.nvim_win_set_option(win, 'foldlevel', 1)
      vim.notify('Response displayed in popup window (press q to close, use zc/zo for folding)', vim.log.levels.INFO)
    end)
  end)()
end, {
  nargs = 0,
  desc = 'Open popup with dictionary definitions of word under cursor using local Yomitan API',
})
