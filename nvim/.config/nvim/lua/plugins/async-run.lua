local function configure_async_run()
  local g = vim.g

  g.asyncrun_open = 20
  g.asyncrun_status = ''
end

return {
  'skywind3000/asyncrun.vim',
  config = configure_async_run,
  keys = {
    -- This is used instead of vim-test
    { '<Leader>tf', '<Cmd>AsyncRun -cwd=<root> -mode=terminal -focus=0 -pos=right npm run test "%:p"<CR>' },
  },
  lazy = false,
}
