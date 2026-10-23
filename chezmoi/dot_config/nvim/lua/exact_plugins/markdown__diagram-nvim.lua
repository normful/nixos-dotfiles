local function configure_diagram_nvim()
  require('diagram').setup({
    integrations = {
      require('diagram.integrations.markdown'),
    },
    renderer_options = {
      mermaid = {
        background = 'transparent',
        theme = 'forest',
        scale = 15,
      },
      plantuml = {
        charset = 'utf-8',
      },
      d2 = {
        theme_id = 1,
      },
      gnuplot = {
        theme = 'dark',
        size = '800,600',
      },
    },
  })
end

return {
  '3rd/diagram.nvim',
  dependencies = { { '3rd/image.nvim' } },
  config = configure_diagram_nvim,
  cond = function()
    return not vim.g.neovide
  end,
}
