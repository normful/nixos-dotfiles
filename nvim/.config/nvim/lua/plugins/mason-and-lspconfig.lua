local function configure_mason_and_lspconfig()
  require('mason').setup()
  require('mason-lspconfig').setup({
    automatic_installation = true,
  })

  local lspconfig = require('lspconfig')

  local on_attach = function(client, bufnr)
    vim.api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = bufnr })

    local opts = { buffer = bufnr, silent = true, noremap = true }

    -- Docs on below:
    -- :help vim.lsp.*
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)

    vim.keymap.set('n', '<Leader>dec', vim.lsp.buf.declaration, opts)

    vim.keymap.set('n', '<Leader>f',   vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<Leader>v',   vim.lsp.buf.definition, opts)
    vim.keymap.set('n', '<Leader>im',  vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<leader>tdef',  vim.lsp.buf.type_definition, opts)

    vim.keymap.set('n', '<Leader>tre',  require('telescope.builtin').lsp_references, opts)
    vim.keymap.set('n', '<Leader>tde',  require('telescope.builtin').lsp_definitions, opts)
    vim.keymap.set('n', '<Leader>ti',  require('telescope.builtin').lsp_implementations, opts)

    vim.keymap.set('n', '<Leader>d',   vim.lsp.buf.signature_help, opts)

    vim.keymap.set('n', '<Leader>re',  vim.lsp.buf.rename, opts)

    client.server_capabilities.document_formatting = true
  end

  local cmp_nvim_lsp = require('cmp_nvim_lsp')
  local capabilities_with_more_completion_candidates = cmp_nvim_lsp.default_capabilities()

  -- Full list of lspconfig.<name> is at
  -- https://github.com/williamboman/mason-lspconfig.nvim?tab=readme-ov-file#available-lsp-servers

  lspconfig.biome.setup({
    on_attach = on_attach,
    capabilities = capabilities_with_more_completion_candidates,
  })

  lspconfig.eslint.setup({
    on_attach = on_attach,
    capabilities = capabilities_with_more_completion_candidates,
  })

  lspconfig.lua_ls.setup({
    on_attach = on_attach,
    capabilities = capabilities_with_more_completion_candidates,
    settings = {
      Lua = {
        runtime = {
          version = 'Lua 5.1',
        },
        diagnostics = {
          globals = { 'vim' },
        },
        workspace = {
          library = vim.api.nvim_get_runtime_file('', true),
          checkThirdParty = false,
        },
        telemetry = {
          enable = false,
        },
      },
    },
  })

  lspconfig.templ.setup({
    on_attach = on_attach,
    capabilities = capabilities_with_more_completion_candidates,
  })

  lspconfig.ts_ls.setup({
    on_attach = on_attach,
    capabilities = capabilities_with_more_completion_candidates,
  })
end

return {
  'williamboman/mason.nvim',
  dependencies = {
    { 'neovim/nvim-lspconfig', lazy = false },
    { 'williamboman/mason-lspconfig.nvim', lazy = false },
    { 'hrsh7th/cmp-nvim-lsp', lazy = false },
  },
  config = configure_mason_and_lspconfig,
  build = ':MasonUpdate',
  lazy = false,
}
