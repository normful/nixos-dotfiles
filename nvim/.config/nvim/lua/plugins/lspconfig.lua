local function configure_lspconfig()
  require('mason').setup()

  require('mason-lspconfig').setup({
    automatic_installation = true,
    ensure_installed = { 'rust_analyzer' },
  })

  local nvchad_lspconfig = require('nvchad.configs.lspconfig')

  nvchad_lspconfig.defaults()

  -- This combines:
  -- https://github.com/NvChad/NvChad/blob/6f25b2739684389ca69ea8229386c098c566c408/lua/nvchad/configs/lspconfig.lua#L35C1-L53C2
  -- https://github.com/hrsh7th/cmp-nvim-lsp/blob/a8912b88ce488f411177fc8aed358b04dc246d7b/lua/cmp_nvim_lsp/init.lua#L37-L86
  local lsp_completion_client_capabilities = vim.tbl_deep_extend('force', {}, require('cmp_nvim_lsp').default_capabilities(), {
    textDocument = {
      completion = {
        completionItem = {
          documentationFormat = {
            'markdown',
            'plaintext',
          },
        },
      },
    },
  })

  local common_lsp_opts = {
    on_attach = require('lsp-on-attach').on_attach,
    on_init = nvchad_lspconfig.on_init,
    -- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#completionClientCapabilities
    capabilities = lsp_completion_client_capabilities,
  }

  -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
  -- Structure: server_name = { specific_options }
  -- Use an empty table {} for servers using only default options.
  local language_servers = {
    -- bash
    bashls = {},

    -- docker
    dockerls = {},
    docker_compose_language_service = {},

    -- TS/JS
    ts_ls = {},
    eslint = {},
    biome = {},

    -- CSS
    cssls = {},

    -- Go
    gopls = {},
    golangci_lint_ls = {},
    templ = {},

    -- Erlang
    elp = {}, -- https://github.com/WhatsApp/erlang-language-platform/blob/main/FAQ.md

    -- Gleam
    gleam = {},

    -- Disabled to avoid conflict with rustaceanvim
    -- rust_analyzer = {},

    -- Spelling and grammar checker
    harper_ls = {
      settings = {
        ['harper-ls'] = {
          linters = {
            SpellCheck = false,
            SentenceCapitalization = false,
          },
        },
      },
    },
  }

  local lspconfig = require('lspconfig')
  for server_name, server_specific_opts in pairs(language_servers) do
    -- Create a new table {} first to avoid modifying common_lsp_opts.
    local final_opts = vim.tbl_deep_extend('force', {}, common_lsp_opts, server_specific_opts)

    if lspconfig[server_name] then
      lspconfig[server_name].setup(final_opts)
    else
      vim.notify('LSP Warning: Configuration not found for ' .. server_name, vim.log.levels.WARN)
    end
  end
end

return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'williamboman/mason.nvim', build = ':MasonUpdate' },
    { 'williamboman/mason-lspconfig.nvim' },
    { 'hrsh7th/cmp-nvim-lsp' },
  },
  init = function()
    local enable_lsp_log = false
    vim.lsp.set_log_level(enable_lsp_log and 'debug' or 'off')
  end,
  config = configure_lspconfig,
}
