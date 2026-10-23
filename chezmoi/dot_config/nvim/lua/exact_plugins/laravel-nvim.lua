return {
  'adalessa/laravel.nvim',
  dependencies = {
    'MunifTanjim/nui.nvim',
    'nvim-lua/plenary.nvim',
    'nvim-neotest/nvim-nio',
  },
  ft = { 'php', 'blade' },
  event = {
    'BufEnter composer.json',
  },
  cmd = { 'Laravel' },
  keys = {
    {
      '<leader>ll',
      function()
        Laravel.pickers.laravel()
      end,
      desc = 'Laravel: Open Laravel Picker',
    },
    {
      '<leader>lv',
      function()
        Laravel.commands.run('view:finder')
      end,
      desc = 'Laravel: Open View Finder',
    },
    {
      '<leader>lr',
      function()
        Laravel.pickers.artisan()
      end,
      desc = 'Laravel: Open Artisan Picker',
    },
    {
      '<leader>la',
      function()
        Laravel.commands.run('actions')
      end,
      desc = 'Laravel: Open Actions Picker',
    },
    {
      '<leader>lr',
      function()
        Laravel.pickers.routes()
      end,
      desc = 'Laravel: Open Routes Picker',
    },
    {
      '<leader>ld',
      function()
        Laravel.run('artisan docs')
      end,
      desc = 'Laravel: Open Documentation',
    },
    {
      '<leader>lm',
      function()
        Laravel.pickers.make()
      end,
      desc = 'Laravel: Open Make Picker',
    },
    {
      '<leader>lcom',
      function()
        Laravel.pickers.commands()
      end,
      desc = 'Laravel: Open Commands Picker',
    },
    {
      '<leader>lo',
      function()
        Laravel.pickers.resources()
      end,
      desc = 'Laravel: Open Resources Picker',
    },
    {
      '<leader>lcc',
      function()
        Laravel.commands.run('command_center')
      end,
      desc = 'Laravel: Open Command Center',
    },
    {
      'gf',
      function()
        local ok, res = pcall(function()
          if Laravel.app('gf').cursorOnResource() then
            return "<cmd>lua Laravel.commands.run('gf')<cr>"
          end
        end)
        if not ok or not res then
          return 'gf'
        end
        return res
      end,
      expr = true,
      noremap = true,
    },
  },
  opts = {
    features = {
      pickers = {
        provider = 'telescope',
      },
    },
  },
}
