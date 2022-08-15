local function get_enabled_lsp_servers()
  local ft_to_server = {
    go = 'gopls',

    html = 'html',

    javascript = 'tsserver',
    javascriptreact = 'tsserver',
    typescript = 'tsserver',
    typescriptreact = 'tsserver',

    css = 'cssls',
    scss = 'cssls',

    ruby = 'solargraph',

    yaml = 'yamlls',
    json = 'jsonls',

    dockerfile = 'dockerls',
    graphql = 'graphql',
    sql = 'sqlls',

    vim = 'vimls',
  }

  local enabled_servers = {}
  for ft, server in pairs(ft_to_server) do
    if vim.tbl_contains(globals.fts_enabled, ft) then
      table.insert(enabled_servers, server)
    end
  end

  return utils.uniq(enabled_servers)
end

local function configure_lsp_config()
  local lspconfig = require('lspconfig')

  -- TODO(norman)
  -- local folding = require('folding')

  local function on_attach(client, bufnr)
    -- completion.on_attach()

    -- TODO(norman)
    -- folding.on_attach()

    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- vim.cmd("autocmd CursorHold <buffer> lua vim.diagnostic.open_float(0, { scope = 'line', border = 'single', source = true })")

    utils.nnoremap_silent_bulk_in_buffer({
      ['K'] = '<Cmd>lua vim.lsp.buf.hover()<CR>',

      ['<Leader>v'] = '<Cmd>lua vim.lsp.buf.definition()<CR>',
      ['<Leader>f'] = '<Cmd>lua vim.lsp.buf.references()<CR>',
      ['<Leader>d'] = '<Cmd>lua vim.lsp.buf.signature_help()<CR>',

      ['<Leader>re'] = '<Cmd>lua vim.lsp.buf.rename()<CR>',

      ['<Leader>ty'] = '<Cmd>lua vim.lsp.buf.type_definition()<CR>',
      ['<Leader>dec'] = '<Cmd>lua vim.lsp.buf.declaration()<CR>',
      ['<Leader>im'] = '<Cmd>lua vim.lsp.buf.implementation()<CR>',
    }, 0)

    if client.resolved_capabilities.document_formatting then
      utils.nnoremap_silent_bulk_in_buffer({
        ['<space>f'] = '<Cmd>lua vim.lsp.buf.formatting()<CR>',
      }, 0)
    end

    if client.resolved_capabilities.document_range_formatting then
      utils.xnoremap_silent_bulk_in_buffer({
        ['<space>f'] = '<Cmd>lua vim.lsp.buf.range_formatting()<CR>',
      }, 0)
    end

-- This is basically "same identifier" highlighting
--   if client.resolved_capabilities.document_highlight then
--     vim.api.nvim_exec([[
--       highlight LspReferenceRead cterm=bold ctermbg=red guibg=#444444
--       highlight LspReferenceText cterm=bold ctermbg=red guibg=#444444
--       highlight LspReferenceWrite cterm=bold ctermbg=red guibg=#444444
--       augroup lsp_document_highlight
--         autocmd! * <buffer>
--         autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
--         autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
--       augroup END
--     ]], false)
--  end
  end

  for _, server in pairs(get_enabled_lsp_servers()) do
    lspconfig[server].setup({
      on_attach = on_attach,
    })
  end
end

configure_lsp_config()

-- TODO
-- {'pierreglaser/folding-nvim'},
