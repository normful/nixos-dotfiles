local function configure_chat_gpt()
  require('chatgpt').setup()
end

return {
  'jackMort/ChatGPT.nvim',
  config = configure_chat_gpt,
  cmd = {
    'ChatGPT',
    'ChatGPTActAs',
    'ChatGPTCompleteCode',
    'ChatGPTEditWithInstructions',
    'ChatGPTRun',
  },
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim"
  }
}
