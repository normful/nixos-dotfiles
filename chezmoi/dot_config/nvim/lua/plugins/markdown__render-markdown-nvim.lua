local function configure_render_markdown_nvim()
  require('render-markdown').setup({
    html = { enabled = false },
    latex = { enabled = false },
    yaml = { enabled = false },
    heading = {
      sign = false,
      width = 'block',
      position = 'inline',
      left_pad = 0,
      right_pad = 2,
    },
    code = {
      sign = false,

      language_border = ' ',
      language_left = '',
      language_right = '',

      width = 'block',
      min_width = 80,

      left_pad = 0,
      language_pad = 0,
    },
    -- https://github.com/MeanderingProgrammer/render-markdown.nvim/wiki/Checkboxes
    checkbox = {
      bullet = true,
      right_pad = 2,
      unchecked = {
        icon = '⏹️',
      },
      checked = {
        icon = '✅',
      },
      custom = {
        progressing = {
          raw = '[.]',
          rendered = '♿️',
          highlight = 'RenderMarkdownProgressing',
          scope_highlight = nil,
        },
        urgent = {
          raw = '[!]',
          rendered = '🆘',
          highlight = 'RenderMarkdownUrgent',
          scope_highlight = nil,
        },
        uncertain = {
          raw = '[?]',
          rendered = 'ℹ️',
          highlight = 'RenderMarkdownUncertain',
          scope_highlight = nil,
        },
        repeating = {
          raw = '[+]',
          rendered = '🔁',
          highlight = 'RenderMarkdownRepeating',
          scope_highlight = nil,
        },
        stopped = {
          raw = '[=]',
          rendered = '⏸️',
          highlight = 'RenderMarkdownStopped',
          scope_highlight = nil,
        },
      },
    },
    bullet = {
      icons = { '▶', '⬥', '✦', '·' },
      left_pad = 0,
      right_pad = 0,
    },
  })

  vim.api.nvim_set_hl(0, 'RenderMarkdownH1Bg', { link = 'Directory' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH2Bg', { link = 'Constant' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH3Bg', { link = 'DiagnosticWarn' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH4Bg', { link = 'Exception' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH5Bg', { link = 'String' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH6Bg', { link = 'DiagnosticHint' })
end

return {
  'MeanderingProgrammer/render-markdown.nvim',
  event = 'VeryLazy',
  config = configure_render_markdown_nvim,
}
