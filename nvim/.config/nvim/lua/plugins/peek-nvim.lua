return {
  'toppair/peek.nvim',
  build = 'deno task --quiet build:fast',
  keys = {
    {
      '<Leader>mp',
      function()
        local peek = require('peek')
        if peek.is_open() then
          peek.close()
        else
          peek.open()
          vim.fn.system('osascript -e \'tell application "Vivaldi" to set bounds of front window to {793, 38, 1512, 982}\'')
        end
      end,
      desc = 'Peek (Markdown Preview)',
    },
  },
  ft = 'markdown',
  opts = {
    theme = 'dark',
    app = 'browser',
  },
}
