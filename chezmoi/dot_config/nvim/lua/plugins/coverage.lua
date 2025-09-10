local function configure_coverage()
  local g = vim.g
  g.coverage_auto_start = 0
  g.coverage_json_report_path = 'coverage/coverage-final.json'
  g.coverage_show_uncovered = 1
  g.coverage_show_covered = 1
  g.coverage_sign_covered = '♺'
  g.coverage_sign_uncovered = '☡'
  g.coverage_override_sign_column_highlight = 0
  g.coverage_interval = 5000
end

return {
  'normful/coverage.vim',
  config = configure_coverage,
  ft = { 'typescript', 'javascript' },
}
