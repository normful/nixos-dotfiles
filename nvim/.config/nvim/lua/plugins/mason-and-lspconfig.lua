local function configure_mason_and_lspconfig()
  require('mason').setup()

  require('mason-lspconfig').setup({
    automatic_installation = true,
  })

  local lspconfig = require('lspconfig')

  -- You can make another similar on_attach function, 
  -- if you need slightly different behaviour for a specific language server.
  local common_on_attach = function(client, bufnr)
    vim.api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = bufnr })

    local opts = { buffer = bufnr, silent = true, noremap = true }

    -- Docs on below:
    -- :help vim.lsp.*
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)

    vim.keymap.set('n', '<Leader>dec', vim.lsp.buf.declaration, opts)

    vim.keymap.set('n', '<Leader>f',   vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<Leader>v',   vim.lsp.buf.definition, opts)
    vim.keymap.set('n', '<Leader>im',  vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<leader>ty',  vim.lsp.buf.type_definition, opts)

    vim.keymap.set('n', '<Leader>tre',  require('telescope.builtin').lsp_references, opts)
    vim.keymap.set('n', '<Leader>tde',  require('telescope.builtin').lsp_definitions, opts)
    vim.keymap.set('n', '<Leader>ti',  require('telescope.builtin').lsp_implementations, opts)

    vim.keymap.set('n', '<Leader>d',   vim.lsp.buf.signature_help, opts)

    vim.keymap.set('n', '<Leader>re',  vim.lsp.buf.rename, opts)

    client.server_capabilities.document_formatting = true
  end

  local cmp_nvim_lsp = require('cmp_nvim_lsp')
  local capabilities_with_more_completion_candidates = cmp_nvim_lsp.default_capabilities()

  -- ---------------------------------------------------------------------------------------------
  -- bash
  -- ---------------------------------------------------------------------------------------------

  -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#bashls
  lspconfig.bashls.setup({
    on_attach = common_on_attach,
    capabilities = capabilities_with_more_completion_candidates,
  })

  -- ---------------------------------------------------------------------------------------------
  -- lua
  -- ---------------------------------------------------------------------------------------------

  -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#lua_ls
  lspconfig.lua_ls.setup({
    on_attach = common_on_attach,
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

  -- ---------------------------------------------------------------------------------------------
  -- docker
  -- ---------------------------------------------------------------------------------------------

  -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#dockerls
  lspconfig.dockerls.setup({
    on_attach = common_on_attach,
    capabilities = capabilities_with_more_completion_candidates,
  })

  -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#docker_compose_language_service
  lspconfig.docker_compose_language_service.setup({
    on_attach = common_on_attach,
    capabilities = capabilities_with_more_completion_candidates,
  })

  -- ---------------------------------------------------------------------------------------------
  -- TS/JS
  -- ---------------------------------------------------------------------------------------------

  -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#ts_ls
  lspconfig.ts_ls.setup({
    on_attach = common_on_attach,
    capabilities = capabilities_with_more_completion_candidates,
  })

  -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#eslint
  lspconfig.eslint.setup({
    on_attach = common_on_attach,
    capabilities = capabilities_with_more_completion_candidates,
  })

  -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#biome
  lspconfig.biome.setup({
    on_attach = common_on_attach,
    capabilities = capabilities_with_more_completion_candidates,
  })

  -- ---------------------------------------------------------------------------------------------
  -- CSS
  -- ---------------------------------------------------------------------------------------------

  -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#cssls
  lspconfig.cssls.setup({
    on_attach = common_on_attach,
    capabilities = capabilities_with_more_completion_candidates,
  })

  -- ---------------------------------------------------------------------------------------------
  -- Go
  -- ---------------------------------------------------------------------------------------------

  -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#gopls
  lspconfig.gopls.setup({
    on_attach = common_on_attach,
    capabilities = capabilities_with_more_completion_candidates,
  })

  -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#golangci_lint_ls
  lspconfig.golangci_lint_ls.setup({
    on_attach = common_on_attach,
    capabilities = capabilities_with_more_completion_candidates,
  })

  -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#templ
  lspconfig.templ.setup({
    on_attach = common_on_attach,
    capabilities = capabilities_with_more_completion_candidates,
  })

  -- ---------------------------------------------------------------------------------------------
  -- Rust
  -- ---------------------------------------------------------------------------------------------

  -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#rust_analyzer
  lspconfig.rust_analyzer.setup({
    on_attach = common_on_attach,
    capabilities = capabilities_with_more_completion_candidates,
  })

  -- ---------------------------------------------------------------------------------------------
  -- Erlang
  -- ---------------------------------------------------------------------------------------------

  -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#elp
  -- https://github.com/WhatsApp/erlang-language-platform/blob/main/FAQ.md
  lspconfig.elp.setup({
    on_attach = common_on_attach,
    capabilities = capabilities_with_more_completion_candidates,
  })

  -- ---------------------------------------------------------------------------------------------
  -- Gleam
  -- ---------------------------------------------------------------------------------------------

  -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#gleam
  lspconfig.gleam.setup({
    on_attach = common_on_attach,
    capabilities = capabilities_with_more_completion_candidates,
  })

  local enableLspLog = false
  vim.lsp.set_log_level(enableLspLog and "debug" or "off")
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
