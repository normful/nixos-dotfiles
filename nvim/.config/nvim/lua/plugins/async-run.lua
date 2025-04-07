local function configure_async_run()
  local g = vim.g

  g.asyncrun_open = 20
  g.asyncrun_status = ''
end

return {
  'skywind3000/asyncrun.vim',
  config = configure_async_run,
  event = 'VeryLazy',
  keys = {
    {
      '<Leader>tf',
      -- This is used instead of vim-test
      '<Cmd>AsyncRun -cwd=<root> -mode=terminal -focus=0 -pos=right npm run test "%:p"<CR>',
      desc = 'Test file (npm test)',
    },
  },
}
