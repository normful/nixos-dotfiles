local function configure_avante()
  require('avante').setup({
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
      jump_result_buffer_on_finish = true,
      support_paste_from_clipboard = true,
    },

    provider = 'openai',

    auto_suggestions_provider = 'claude',

    copilot = {
      model = 'claude-3.5-sonnet',
    },

    gemini = {
      model = 'gemini-2.0-flash-exp',
      -- model = 'gemini-2.0-flash-thinking-exp-1219',
    },

    openai = {
      endpoint = 'https://aihubmix.com/v1',
      model = 'gpt-4o-mini',
      -- model = 'gemini-2.0-pro-exp-02-05',
      -- model = "o1-preview",
      -- model = 'claude-3-5-sonnet-latest',
    },

    file_selector = {
      provider = 'telescope',
    },

    vendors = {
      mistral = {
        __inherited_from = 'openai',
        endpoint = 'https://api.mistral.ai/v1',
        api_key_name = 'MISTRAL_API_KEY',
        model = 'codestral-latest',
      },
      openrouter = {
        __inherited_from = 'openai',
        endpoint = 'https://openrouter.ai/api/v1',
        api_key_name = 'OPENROUTER_API_KEY',
        model = '',
      },
      ollama = {
        __inherited_from = 'openai',
        api_key_name = '',
        endpoint = 'http://localhost:11434/v1',
        model = 'phi4:14b-fp16',
      },
      mlc = {
        __inherited_from = 'openai',
        api_key_name = '',
        endpoint = 'http://localhost:8000/v1',
        model = 'qwen2.5-coder:32b',
      },
      groq = {
        __inherited_from = 'openai',
        api_key_name = 'GROQ_API_KEY',
        endpoint = 'https://api.groq.com/openai/v1/',
        model = 'deepseek-r1-distill-llama-70b',
      },
      perplexity = {
        __inherited_from = 'openai',
        api_key_name = 'PPLX_API_KEY',
        endpoint = 'https://api.perplexity.ai',
        model = 'llama-3.1-sonar-large-128k-online',
      },
    },
  })
end

return {
  'yetone/avante.nvim',
  dependencies = {
    { 'stevearc/dressing.nvim' },
    { 'nvim-lua/plenary.nvim' },
    { 'MunifTanjim/nui.nvim' },
  },
  config = configure_avante,
  build = 'make',
  lazy = false,
  version = false,
}
