local function configure_image_nvim()
  require('image').setup({
    backend = 'kitty',
    integrations = {
      markdown = {
        only_render_image_at_cursor = true,
        floating_windows = true,
      },
    },
  })
end

return {
  '3rd/image.nvim',
  ft = { 'markdown', 'norg' },
  config = configure_image_nvim,
  cond = function()
    return not vim.g.neovide
  end,
}
