local my_linters = {
  scss = { 'stylelint' },

  -- markdown = { 'markdownlint' },

  ruby = { 'brakeman', 'rails_best_practices', 'reek', 'rubocop', 'ruby' },

  javascript = { 'tsserver', 'eslint' },
  javascriptreact = { 'tsserver', 'eslint' },
  typescript = { 'tsserver', 'eslint' },
  typescriptreact = { 'tsserver', 'eslint' },
}

local my_fixers = {
  scss = { 'stylelint', 'trim_whitespace', 'remove_trailing_lines' },

  sh = { 'trim_whitespace', 'remove_trailing_lines' },

  javascript = { 'prettier' },
  javascriptreact = { 'prettier' },
  typescript = { 'prettier' },
  typescriptreact = { 'prettier' },
}

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
  local final_linters = {}
  for ft, linters in pairs(my_linters) do
    final_linters[ft] = linters
  end
  g.ale_linters = final_linters

  -- Fixer settings
  g.ale_fix_on_save = 1
  local final_fixers = {}
  for ft, fixers in pairs(my_fixers) do
    final_fixers[ft] = fixers
  end
  g.ale_fixers = final_fixers

  -- Other settings
  g.ale_warn_about_trailing_whitespace = 0
  g.ale_maximum_file_size = 1024 * 1024
  g.ale_completion_enabled = 0

  vim.cmd([[highlight! ALEErrorSign        ctermbg=236 ctermfg=Red]])
  vim.cmd([[highlight! ALEWarningSign      ctermbg=236 ctermfg=Yellow]])
  vim.cmd([[highlight! ALEInfoSign         ctermbg=236 ctermfg=Blue]])
  vim.cmd([[highlight! ALEStyleErrorSign   ctermbg=236 ctermfg=Red]])
  vim.cmd([[highlight! ALEStyleWarningSign ctermbg=236 ctermfg=Yellow]])
end

return {
  'dense-analysis/ale',
  configure = configure_ale,
}
