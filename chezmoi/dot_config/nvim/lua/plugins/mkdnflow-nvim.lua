local function configure_mkdnflow_nvim()
  require('mkdnflow').setup({
    modules = {
      maps = true,
      tables = true,
      buffers = true,
      cursor = true,
      links = true,
      lists = true,
      paths = true,
      cmp = true,

      bib = false,
      conceal = false,
      yaml = false,

      -- Tried these but they didn't work well.
      -- I use MeanderingProgrammer/render-markdown.nvim instead.
      folds = false,
      foldtext = false,
    },
    links = {
      style = 'markdown',
      transform_explicit = function(_)
        local charset = 'abcdefghijklmnopqrstuvwxyz0123456789'
        local result = ''
        for _ = 1, 8 do
          local index = math.random(1, #charset)
          result = result .. charset:sub(index, index)
        end
        return result
      end,
    },
    mappings = {
      MkdnEnter = { { 'n', 'v' }, '<CR>' },

      -- Instead of MkdnCreateLinkFromClipboard,
      -- I'm using a custom user function mapped to <Leader>zl that wraps MkdnCreateLinkFromClipboard

      MkdnGoBack = { 'n', '[[' },
      MkdnGoForward = { 'n', ']]' },

      MkdnNewListItem = { 'i', '<CR>' },
      MkdnNewListItemBelowInsert = { 'n', 'o' },
      MkdnNewListItemAboveInsert = { 'n', 'O' },

      MkdnUpdateNumbering = { 'n', 'rn' },
      MkdnIncreaseHeading = { 'n', '-' },
      MkdnDecreaseHeading = { 'n', '+' },

      -- MkdnTagSpan = { 'v', '<Leader>ts' },

      -- These didn't work for me
      -- MkdnYankAnchorLink = { 'n', '<Leader>zh' },
      -- MkdnYankFileAnchorLink = { 'n', '<Leader>zy' },

      --[[ MkdnTableNextCell = { 'i', '<Tab>' },
      MkdnTablePrevCell = { 'i', '<S-Tab>' },
      MkdnTableNextRow = false,
      MkdnTablePrevRow = { 'i', '<M-CR>' },
      MkdnTableNewRowBelow = { 'n', '<leader>ir' },
      MkdnTableNewRowAbove = { 'n', '<leader>iR' },
      MkdnTableNewColAfter = { 'n', '<leader>ic' },
      MkdnTableNewColBefore = { 'n', '<leader>iC' }, ]]
    },
    new_file_template = {
      use_template = true,
      placeholders = {
        before = {
          day_of_week = function()
            return os.date('%A')
          end,
          iso_8601_date = function()
            local t = os.time()
            local offset = os.date('%z', t)
            return os.date('%Y-%m-%dT%H:%M:%S', t) .. offset
          end,
        },
      },
      template = [[
---
title: {{ title }}
day: {{ day_of_week }}
date: {{ iso_8601_date }}
author: Norman Sue
tags: []
aliases: []
---


]],
    },
    perspective = {
      priority = 'root',
      root_tell = '.git',
    },

    -- Should keep aligned with the custom checkboxes configured in
    -- MeanderingProgrammer/render-markdown.nvim config.
    to_do = {
      symbols = { ' ', '.', '!', '?', '+', '=', 'x' },
      not_started = ' ',
      in_progress = '.',
      complete = 'x',
      update_parents = true,
    },
  })
end

return {
  'jakewvincent/mkdnflow.nvim',
  ft = { 'markdown' },
  config = configure_mkdnflow_nvim,
}
