local function configure_rusteaceanvim()
  local common_on_attach = require('lsp-on-attach').on_attach

  ---@type rustaceanvim.Opts
  vim.g.rustaceanvim = {
    ---@type rustaceanvim.tools.Opts
    tools = {
      test_executor = 'background',
    },

    ---@type rustaceanvim.lsp.ClientOpts
    server = {
      on_attach = function(client, bufnr)
        common_on_attach(client, bufnr)

        local function opts(desc)
          return { buffer = bufnr, desc = 'rust-analyzer: ' .. desc }
        end

        vim.keymap.set('n', '<Leader>r', function()
          vim.cmd.RustLsp({ 'runnables', bang = true })
        end, opts('prev runnable'))

        vim.keymap.set('n', '<Leader>tt', function()
          vim.cmd.RustLsp({ 'testables', bang = true })
        end, opts('prev testable'))

        vim.keymap.set('n', '<Leader>db', function()
          vim.cmd.RustLsp({ 'debuggables', bang = true })
        end, opts('prev debuggable'))

        vim.keymap.set({ 'n', 'v' }, '<Leader>ca', function()
          vim.cmd.RustLsp('codeAction')
        end, opts('code action'))
      end,

      -- rustaceanvim already informs rust-analyzer about completion client capabilities in
      -- https://github.com/mrcjkb/rustaceanvim/blob/e9c5aaba16fead831379d5f44617547a90b913c7/lua/rustaceanvim/config/server.lua#L135

      default_settings = {
        -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#rust_analyzer
        ['rust-analyzer'] = {
          -- https://rust-analyzer.github.io/book/configuration.html
          cargo = {
            features = { 'all' },
          },
          check = {
            features = { 'all' },
          },
          diagnostics = {
            enable = true,
            experimental = {
              enable = true,
            },
            styleLints = {
              enable = true,
            },
            warningsAsHint = {
              'missing_docs',
            },
          },
        },
      },
    },

    ---@type rustaceanvim.dap.Opts
    -- dap = {},
  }
end

return {
  'mrcjkb/rustaceanvim',
  version = '^5',
  config = configure_rusteaceanvim,
  ft = 'rust',
}
