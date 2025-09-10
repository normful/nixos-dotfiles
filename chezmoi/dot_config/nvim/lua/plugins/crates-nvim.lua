return {
  'saecki/crates.nvim',
  tag = 'stable',
  ---@type crates.UserConfig
  opts = {
    completion = {
      crates = {
        enabled = true,
      },
    },
    lsp = {
      enabled = true,
      actions = true,
      completion = true,
      hover = true,
    },
  },
  event = { 'BufRead Cargo.toml' },
}
