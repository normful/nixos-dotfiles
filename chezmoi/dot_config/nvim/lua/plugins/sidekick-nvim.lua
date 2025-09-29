return {
  'folke/sidekick.nvim',
  ---@class sidekick.Config
  opts = {},
  keys = {
    {
      '<tab>',
      function()
        -- if there is a next edit, jump to it, otherwise apply it if any
        if not require('sidekick').nes_jump_or_apply() then
          return '<Tab>' -- fallback to normal tab
        end
      end,
      expr = true,
      desc = 'Goto/Apply Next Edit Suggestion',
    },
    {
      '<leader>sa',
      function()
        require('sidekick.cli').toggle({ focus = true })
      end,
      desc = 'Sidekick Toggle CLI',
      mode = { 'n', 'v' },
    },
    {
      '<leader>sc',
      function()
        require('sidekick.cli').toggle({ name = 'claude', focus = true })
      end,
      desc = 'Sidekick Claude Toggle',
      mode = { 'n', 'v' },
    },
    {
      '<leader>sg',
      function()
        require('sidekick.cli').toggle({ name = 'grok', focus = true })
      end,
      desc = 'Sidekick Grok Toggle',
      mode = { 'n', 'v' },
    },
    {
      '<leader>sp',
      function()
        require('sidekick.cli').select_prompt()
      end,
      desc = 'Sidekick Ask Prompt',
      mode = { 'n', 'v' },
    },
  },
}
