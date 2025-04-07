local M = {}

M.on_attach = function(client, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = 'LSP ' .. desc }
  end
  local map = vim.keymap.set

  -- The `require('telescope.builtin').lsp_` are wrappers around
  -- functions explained in `:help vim.lsp.*`

  -- Reading and navigating code
  map('n', 'K', vim.lsp.buf.hover, opts('Info on cursor symbol'))
  map('n', '<Leader>dec', vim.lsp.buf.declaration, opts('Go to declaration'))
  map('n', '<Leader>v', require('telescope.builtin').lsp_definitions, opts('Go to definition'))
  map('n', '<Leader>f', require('telescope.builtin').lsp_references, opts('References (telescope)'))
  map('n', '<Leader>im', require('telescope.builtin').lsp_implementations, opts('List implementations'))
  map('n', '<Leader>ty', require('telescope.builtin').lsp_type_definitions, opts('Go to type def'))
  map('n', '<Leader>in', require('telescope.builtin').lsp_incoming_calls, opts('List calls to cursor symbol'))
  map('n', '<Leader>out', require('telescope.builtin').lsp_outgoing_calls, opts('List items called by symbol'))
  map('n', '<Leader>sy', require('telescope.builtin').lsp_document_symbols, opts('List doc syms in buffer'))
  map('n', '<Leader>wsy', require('telescope.builtin').lsp_workspace_symbols, opts('List doc syms in workspace'))
  map('n', '<Leader>d', vim.lsp.buf.signature_help, opts('Signature'))

  -- Writing code
  map('n', '<Leader>dia', require('telescope.builtin').diagnostics, opts('List diagnostics in buffer'))
  map('n', '<Leader>re', require('nvchad.lsp.renamer'), opts('Rename'))
  map({ 'n', 'v' }, '<Leader>ca', vim.lsp.buf.code_action, opts('Code action'))

  -- Additional lines in previous on_attach.
  -- TODO(norman): Decide whether these are still needed
  -- vim.api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = bufnr })
  -- client.server_capabilities.document_formatting = true
end

return M
