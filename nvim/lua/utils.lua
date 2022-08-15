utils = {}

function utils.has(key)
    return vim.fn.has(key) == 1
end

function utils.set(option_name, value, scopes)
  for _, scope in pairs(scopes or { vim.o }) do
    scope[option_name] = value
  end
end

-- Avoid using set_append, because reloading vim config will result in duplicate text in the setting's value.
function utils.set_append(option_name, value, scopes)
  for _, scope in pairs(scopes or { vim.o }) do
    local prev = scope[option_name]
    scope[option_name] = prev .. value
  end
end

-- Less sophisticated fallback. Prefer using `utils.set`.
function utils.set2(expression)
  vim.api.nvim_command(string.format("set " .. expression))
end

--[[
   Bulk keymapping helper functions
--]]

local function set_bulk_mappings(mappings, mode, opts)
  for lhs, rhs in pairs(mappings) do
    vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
  end
end

function utils.nnoremap_silent_bulk(mappings)
  set_bulk_mappings(mappings, 'n', { noremap = true, silent = true })
end

function utils.inoremap_silent_bulk(mappings)
  set_bulk_mappings(mappings, 'i', { noremap = true, silent = true })
end

-- Avoid vmap and vnoremap, according to https://vi.stackexchange.com/questions/11852/should-i-use-xmap-or-vmap-in-my-mappings
function utils.vnoremap_silent_bulk(mappings)
  set_bulk_mappings(mappings, 'v', { noremap = true, silent = true })
end

function utils.cnoremap_silent_bulk(mappings)
  set_bulk_mappings(mappings, 'c', { noremap = true, silent = true })
end

function utils.tnoremap_silent_bulk(mappings)
  set_bulk_mappings(mappings, 't', { noremap = true, silent = true })
end

function utils.xnoremap_silent_bulk(mappings)
  set_bulk_mappings(mappings, 'x', { noremap = true, silent = true })
end

function utils.inoremap_silent_expr_bulk(mappings)
  set_bulk_mappings(mappings, 'i', { noremap = true, silent = true, expr = true })
end

function utils.nmap_silent_bulk(mappings)
  set_bulk_mappings(mappings, 'n', { noremap = false, silent = true })
end

--[[
   Buffer-specific bulk keymapping helper functions
--]]

local function set_bulk_mappings_in_buffer(mappings, mode, opts, buf_nr)
  for lhs, rhs in pairs(mappings) do
    vim.api.nvim_buf_set_keymap(buf_nr, mode, lhs, rhs, opts)
  end
end

function utils.nnoremap_silent_bulk_in_buffer(mappings, buf_nr)
  set_bulk_mappings_in_buffer(mappings, 'n', { noremap = true, silent = true }, buf_nr)
end

function utils.vnoremap_silent_bulk_in_buffer(mappings, buf_nr)
  set_bulk_mappings_in_buffer(mappings, 'v', { noremap = true, silent = true }, buf_nr)
end

function utils.xnoremap_silent_bulk_in_buffer(mappings, buf_nr)
  set_bulk_mappings_in_buffer(mappings, 'x', { noremap = true, silent = true }, buf_nr)
end


function utils.create_augroups(definitions)
  for group_name, definition in pairs(definitions) do
    vim.cmd('augroup '..group_name)
    vim.cmd('autocmd!')
    for _, def in ipairs(definition) do
      local command = table.concat(vim.tbl_flatten{'autocmd', def}, ' ')
      vim.cmd(command)
    end
    vim.cmd('augroup END')
  end
end

function utils.uniq(tbl)
  local hash = {}
  local res = {}
  for _,v in ipairs(tbl) do
    if (not hash[v]) then
       res[#res+1] = v
       hash[v] = true
    end
  end
  return res
end

--[[
Param plugin_fts: table of filetypes that the plugin works with
Returns filtered table of filetypes that are enabled in globals
--]]
function utils.enabled_fts(plugin_fts)
  local filter_fn = function(this_ft)
    return vim.tbl_contains(globals.fts_enabled, this_ft)
  end

  return vim.tbl_filter(filter_fn, plugin_fts)
end
