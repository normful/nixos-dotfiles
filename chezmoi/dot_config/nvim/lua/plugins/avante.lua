return {
  'yetone/avante.nvim',
  version = false,
  build = 'make',
  dependencies = {
    { 'stevearc/dressing.nvim' },
    { 'nvim-lua/plenary.nvim' },
    { 'MunifTanjim/nui.nvim' },
  },
  cmd = { 'AvanteAsk', 'AvanteChat', 'AvanteToggle' },
  ---@type avante.Config
  opts = {
    -- See defaults at https://github.com/yetone/avante.nvim/blob/main/lua/avante/config.lua
    -- Model-related config copied from https://github.com/yetone/cosmos-nvim/blob/main/lua/layers/completion/plugins.lua

    mappings = {
      submit = {
        insert = '<D-s>',
      },
    },

    windows = {
      width = 70,
      sidebar_header = {
        align = 'right',
      },
    },

    behaviour = {
      auto_suggestions = true,
      auto_apply_diff_after_generation = true,
      support_paste_from_clipboard = true,
      auto_approve_tool_permissions = true,
    },

    auto_suggestions_provider = 'aihubmix',
    memory_summary_provider = 'aihubmix',
    provider = 'aihubmix',

    providers = {
      aihubmix = {
        model = 'Qwen3-Coder', -- $2.16/M output tokens
        -- model = 'qwen3-coder-plus-2025-07-22', -- $1.08/M output tokens
        -- model = 'qwen3-coder-480b-a35b-instruct', -- $5.6/M output tokens
      },
    },

    file_selector = {
      provider = 'telescope',
    },
  },
  keys = {
    {
      '<Leader>aa',
      '<Cmd>AvanteAsk<CR>',
      mode = 'n',
      desc = 'Avante: ask',
    },
  },
}
