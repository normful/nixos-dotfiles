local function configure_lspconfig()
  require('mason').setup()

  require('mason-lspconfig').setup({
    -- Visit https://mason-registry.dev/registry/list to see all installable by Mason
    -- Equivalently: see https://github.com/search?q=repo%3Amason-org%2Fmason-registry+neovim%3A+lspconfig%3A&type=code
    ensure_installed = {
      -- Some tools are installed by Nix, so they're not listed here

      'nil_ls',
      'bashls',
      'dockerls',
      'docker_compose_language_service',
      'ts_ls',
      'eslint',
      'biome',
      'cssls',
      'golangci_lint_ls',
      'elp',
      'basedpyright',
      'harper_ls',
      'copilot',

      'rust_analyzer',
    },
    automatic_enable = false,
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

  -- See https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
  -- for all language servers you can configure below.
  --
  -- Structure: server_name = { specific_options }
  -- Use an empty table {} for servers using only default options.
  local language_servers = {
    -- nix
    nil_ls = {},

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

    -- PHP
    intelephense = {
      settings = {
        intelephense = {
          -- See https://github.com/bmewburn/vscode-intelephense/wiki/Installation#configuration-options
          files = {
            associations = {
              '*.php',
              '*.phtml',
              '*.html',
              '*.inc',
            },
          },
          environment = {
            includePaths = {
              'vendor',
              -- 'stubs/stubs.php',
            },
            phpVersion = '8.4.12',
          },
          codeLens = {
            references = { enable = true },
            implementations = { enable = true },
            usages = { enable = true },
            overrides = { enable = true },
            parent = { enable = true },
          },
        },
      },
    },
    -- Purposely not using: psalm, phpactor

    -- Python
    basedpyright = {},

    -- Disabled to avoid conflict with rustaceanvim
    -- rust_analyzer = {},

    -- Spelling and grammar checker
    harper_ls = {
      filetypes = {
        'neorg',
      },
      settings = {
        ['harper-ls'] = {
          linters = {
            SpellCheck = true,
            SentenceCapitalization = false,
          },
        },
      },
    },

    copilot = {},
  }

  for server_name, server_specific_opts in pairs(language_servers) do
    -- Create a new table {} first to avoid modifying common_lsp_opts.
    local final_opts = vim.tbl_deep_extend('force', {}, common_lsp_opts, server_specific_opts)

    vim.lsp.config(server_name, final_opts)
    vim.lsp.enable(server_name)
  end
end

return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'mason-org/mason.nvim', build = ':MasonUpdate' },
    { 'mason-org/mason-lspconfig.nvim' },
    { 'hrsh7th/cmp-nvim-lsp' },
  },
  init = function()
    -- Note to self!
    -- Toggle this boolean below manually when you want to see
    -- more verbose logging temporarily in :LspLog
    local enable_lsp_log = false

    vim.lsp.set_log_level(enable_lsp_log and 'debug' or 'off')
  end,
  config = configure_lspconfig,
}
