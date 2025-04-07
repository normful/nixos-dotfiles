return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  -- https://github.com/stevearc/conform.nvim?tab=readme-ov-file#setupopts
  ---@module "conform"
  ---@type conform.setupOpts
  opts = {
    -- https://github.com/stevearc/conform.nvim/tree/master/lua/conform/formatters
    formatters_by_ft = {
      lua = { 'stylua' },
      bash = { 'shfmt' },
      nix = { 'nixfmt' },
      javascript = { 'prettierd', 'eslint_d' },
      javascriptreact = { 'prettierd', 'eslint_d' },
      typescript = { 'prettierd', 'eslint_d' },
      typescriptreact = { 'prettierd', 'eslint_d' },
      svelte = { 'prettierd', 'eslint_d' },
      vue = { 'prettierd', 'eslint_d' },
      css = { 'prettierd', 'stylelint' },
      scss = { 'prettierd', 'stylelint' },
      ruby = { 'rubocop', 'rubyfmt' },
      python = { 'black' },
      go = { 'gofmt', 'goimports' },
      gleam = { 'gleam' },
      rust = {}, -- To avoid conflicting "https://github.com/mantoni/eslint_d.jswith rustaceanvim
      -- For all filetypes:
      ['*'] = { 'trim_newlines', 'trim_whitespace' },
      -- For filetypes that don't have other formatters configured:
      ['_'] = { 'trim_newlines', 'trim_whitespace' },
    },
    default_format_opts = {
      lsp_format = 'fallback', -- Use LSP formatting when no other formatters are available
    },
    format_on_save = {
      lsp_format = 'fallback', -- Use LSP formatting when no other formatters are available
      timeout_ms = 500,
    },
  },
  init = function()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
