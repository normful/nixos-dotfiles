local utils = require('utils')

local configured_fts = {
  'go',
  'ruby',
  'javascript',
  'javascriptreact',
  'typescript',
  'typescriptreact',
}

local function create_augroup_for_ft(ft, skip_all_tests_mapping)
  local autocmds = {
    { 'FileType', ft, [[nnoremap <silent> <Leader>tt <Cmd>TestNearest<CR>]] },
    { 'FileType', ft, [[nnoremap <silent> <Leader>tf <Cmd>TestFile<CR>]] },
  }

  if not skip_all_tests_mapping then
    table.insert(autocmds, { 'FileType', ft, [[nnoremap <silent> <Leader>ta <Cmd>TestSuite<CR>]] })
  end

  utils.create_augroups({
    [('vim_test_%s_augroup'):format(ft)] = autocmds,
  })
end

local function configure()
  local globals = require('globals')
  local g = vim.g

  g['test#strategy'] = 'neovim'
  g['test#preserve_screen'] = 1
  g['test#neovim#term_position'] = 'vert botright 80'

  local runners = {}

  if vim.tbl_contains(globals.fts_enabled, 'go') then
    create_augroup_for_ft('go')
    table.insert(runners, 'go#ginkgo')
  end

  if vim.tbl_contains(globals.fts_enabled, 'ruby') then
    create_augroup_for_ft('ruby', true)

    table.insert(runners, 'ruby#rspec')

    g['test#ruby#rspec#executable'] = 'foreman run spring rspec'
    g['test#ruby#use_spring_binstub'] = 1
    g['test#ruby#use_binstubs'] = 0
    g['test#ruby#bundle_exec'] = 0
    g['test#ruby#rspec#options'] = {
      file = '--fail-fast',
    }
  end

  if vim.tbl_contains(globals.fts_enabled, 'javascript') then
    create_augroup_for_ft('javascript')
    table.insert(runners, 'javascript#jest')

    g['test#javascript#jest#options'] = {
      file = '--updateSnapshot',
      suite = '--coverage',
    }
  end

  if vim.tbl_contains(globals.fts_enabled, 'javascriptreact') then
    create_augroup_for_ft('javascriptreact')
    table.insert(runners, 'javascript#jest')
  end

  if vim.tbl_contains(globals.fts_enabled, 'typescript') then
    create_augroup_for_ft('typescript')
    table.insert(runners, 'typescript#jest')

    g['test#typescript#jest#options'] = {
      file = '--updateSnapshot',
      suite = '--coverage',
    }
  end

  if vim.tbl_contains(globals.fts_enabled, 'typescriptreact') then
    create_augroup_for_ft('typescriptreact')
    table.insert(runners, 'typescript#jest')
  end

  g['test#enabled_runners'] = utils.uniq(runners)
end

return {
  name = 'normful/vim-test',
  configure = configure,
  ft = utils.enabled_fts(configured_fts),
}
