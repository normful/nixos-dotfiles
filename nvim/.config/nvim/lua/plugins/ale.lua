local function configure_ale()
  local g = vim.g

  -- Run :ALEInfo to get debugging info

  -- Signs
  --g.ale_sign_error         = '\\u25A9'
  --g.ale_sign_warning       = '\\u25CC'
  --g.ale_sign_info          = '\\u25CC'
  --g.ale_sign_style_error   = '\\u25A9'
  --g.ale_sign_style_warning = '\\u26CC'

  -- Linter settings
  g.ale_linters_explicit = 1
  g.ale_lint_on_text_changed = 'never'
  g.ale_lint_on_insert_leave = 1
  g.ale_linters = {
    javascript = { 'tsserver', 'eslint' },
    javascriptreact = { 'tsserver', 'eslint' },
    ruby = { 'brakeman', 'rails_best_practices', 'reek', 'rubocop', 'ruby' },
    scss = { 'stylelint' },
    typescript = { 'tsserver', 'eslint' },
    typescriptreact = { 'tsserver', 'eslint' },
  }

  -- Fixer settings
  g.ale_fix_on_save = 1
  g.ale_fixers = {
    ['*'] = { 'remove_trailing_lines', 'trim_whitespace' },
    css = { 'prettier', 'stylelint' },
    go = { 'trim_whitespace', 'remove_trailing_lines', 'goimports', 'gofmt' },
    javascript = { 'biome', 'eslint' },
    javascriptreact = { 'prettier', 'biome', 'eslint' },
    json = { 'prettier', 'biome', 'eslint' },
    lua = { 'stylua' },
    rust = { 'rustfmt' },
    scss = { 'prettier', 'stylelint' },
    sh = { 'trim_whitespace', 'remove_trailing_lines' },
    typescript = { 'prettier', 'biome', 'eslint' },
    typescriptreact = { 'prettier', 'biome', 'eslint' },
  }

  -- Other settings
  g.ale_warn_about_trailing_whitespace = 0
  g.ale_maximum_file_size = 1024 * 1024
  g.ale_completion_enabled = 0

  vim.api.nvim_set_hl(0, 'ALEErrorSign', { ctermbg = 236, ctermfg = 'Red' })
  vim.api.nvim_set_hl(0, 'ALEWarningSign', { ctermbg = 236, ctermfg = 'Yellow' })
  vim.api.nvim_set_hl(0, 'ALEInfoSign', { ctermbg = 236, ctermfg = 'Blue' })
  vim.api.nvim_set_hl(0, 'ALEStyleErrorSign', { ctermbg = 236, ctermfg = 'Red' })
  vim.api.nvim_set_hl(0, 'ALEStyleWarningSign', { ctermbg = 236, ctermfg = 'Yellow' })
end

return {
  'dense-analysis/ale',
  config = configure_ale,
}
