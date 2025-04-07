return {
  'jake-stewart/multicursor.nvim',
  branch = '1.0',
  event = 'VeryLazy',
  config = function()
    local mc = require('multicursor-nvim')
    mc.setup()

    local set = vim.keymap.set

    -- Add a cursor for all matches of cursor word/selection in the document
    set({ 'n', 'x' }, '<Leader>mc', mc.matchAllAddCursors, { desc = 'Multi cursors for word under cursor' })

    -- Mappings defined in a keymap layer only apply when there are
    -- multiple cursors. This lets you have overlapping mappings
    mc.addKeymapLayer(function(layerSet)
      -- Select a different cursor
      layerSet({ 'n', 'x' }, '<Up>', mc.prevCursor)
      layerSet({ 'n', 'x' }, '<Down>', mc.nextCursor)

      -- Delete the currently selected cursor
      layerSet({ 'n', 'x' }, '<Leader>x', mc.deleteCursor)

      -- Enable and clear cursors using escape
      layerSet('n', '<Esc>', function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
        end
      end)
    end)

    -- Customize how cursors look.
    local hl = vim.api.nvim_set_hl
    hl(0, 'MultiCursorCursor', { link = 'Cursor' })
    hl(0, 'MultiCursorVisual', { link = 'Visual' })
    hl(0, 'MultiCursorSign', { link = 'SignColumn' })
    hl(0, 'MultiCursorMatchPreview', { link = 'Search' })
    hl(0, 'MultiCursorDisabledCursor', { link = 'Visual' })
    hl(0, 'MultiCursorDisabledVisual', { link = 'Visual' })
    hl(0, 'MultiCursorDisabledSign', { link = 'SignColumn' })
  end,
}
