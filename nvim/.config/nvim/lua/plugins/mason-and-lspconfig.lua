local function configure_mason_and_lspconfig()
  local lspconfig = require('lspconfig')

  require('mason').setup()

  require('mason-lspconfig').setup({
    ensure_installed = {
      'biome',
      'eslint',
      'lua_ls',
      'tsserver',
    },
  })

  lspconfig.biome.setup({})
  lspconfig.eslint.setup({})
  lspconfig.lua_ls.setup({
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
      }
    }
  })
  lspconfig.tsserver.setup({})

  vim.api.nvim_create_autocmd('LspAttach', {
    -- group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
      -- Enable completion triggered by <C-x><C-o>
      vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

      local bufLocalMappingOpts = { buffer = ev.buf }

      -- Docs on below:
      -- :help vim.lsp.* 
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufLocalMappingOpts)
      vim.keymap.set('n', '<Leader>dec', vim.lsp.buf.declaration, bufLocalMappingOpts)
      vim.keymap.set('n', '<Leader>im', vim.lsp.buf.implementation, bufLocalMappingOpts)
      vim.keymap.set('n', '<Leader>ty', vim.lsp.buf.type_implementation, bufLocalMappingOpts)
      vim.keymap.set('n', '<Leader>v', vim.lsp.buf.definition, bufLocalMappingOpts)
      vim.keymap.set('n', '<Leader>f', vim.lsp.buf.references, bufLocalMappingOpts)
      vim.keymap.set('n', '<Leader>d', vim.lsp.buf.signature_help, bufLocalMappingOpts)
      vim.keymap.set('n', '<Leader>re', vim.lsp.buf.rename, bufLocalMappingOpts)

      -- NOTE(norman): I have not used the below yet
      vim.keymap.set('n', '<Leader>fo', function()
        vim.lsp.buf.format { async = true }
      end)
    end,
  })
end

return {
  'williamboman/mason.nvim',
  dependencies = {
    { 'neovim/nvim-lspconfig' },
    { 'williamboman/mason-lspconfig.nvim' },
  },
  config = configure_mason_and_lspconfig,
  build = ':MasonUpdate',
  lazy = false,
}
