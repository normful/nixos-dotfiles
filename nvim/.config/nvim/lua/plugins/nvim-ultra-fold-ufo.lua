local function fold_virt_text_handler(virtText, lnum, endLnum, width, truncate)
  local newVirtText = {}
  local suffix = (' … %d folded lines'):format(endLnum - lnum)
  local sufWidth = vim.fn.strdisplaywidth(suffix)
  local targetWidth = width - sufWidth
  local curWidth = 0
  for _, chunk in ipairs(virtText) do
    local chunkText = chunk[1]
    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
    if targetWidth > curWidth + chunkWidth then
      table.insert(newVirtText, chunk)
    else
      chunkText = truncate(chunkText, targetWidth - curWidth)
      local hlGroup = chunk[2]
      table.insert(newVirtText, { chunkText, hlGroup })
      chunkWidth = vim.fn.strdisplaywidth(chunkText)
      if curWidth + chunkWidth < targetWidth then
        suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
      end
      break
    end
    curWidth = curWidth + chunkWidth
  end
  table.insert(newVirtText, { suffix, 'MoreMsg' })
  return newVirtText
end

return {
  'kevinhwang91/nvim-ufo',
  dependencies = {
    { 'kevinhwang91/promise-async' },
  },
  event = 'VeryLazy',
  init = function()
    local opt = vim.opt_global
    opt.foldcolumn = '0'
    opt.foldlevel = 99
    opt.foldlevelstart = 99
    opt.foldenable = true
  end,
  opts = {
    provider_selector = function()
      return { 'treesitter', 'indent' }
    end,
    fold_virt_text_handler = fold_virt_text_handler,
  },
  keys = {
    -- See `:h fold` docs for more folding basics
    { '~', 'za', desc = 'Toggle fold under cursor' },
    { 'za', desc = 'Toggle fold under cursor' },
    { 'zA', desc = 'Recursively toggle folds under cursor' },

    { 'zo', desc = 'Open fold under cusor' },
    { 'zc', desc = 'Close fold under cursor ' },

    { 'zO', desc = 'Open folds under cursor recursively' },
    { 'zC', desc = 'Close folds under cursor recursively' },

    {
      'zr',
      "<Cmd>lua require('ufo').openFoldsExceptKinds()<CR>",
      desc = 'Open folds',
    },
    { 'zm', "<Cmd>lua require('ufo').closeFoldsWith()<CR>", desc = 'Close folds with' },

    {
      'zR',
      "<Cmd>lua require('ufo').openAllFolds()<CR>",
      desc = 'Open all folds, keeping foldlevel',
    },
    {
      'zM',
      "<Cmd>lua require('ufo').closeAllFolds()<CR>",
      desc = 'Close all folds, keeping foldlevel',
    },

    { '[z', desc = 'Go to start of current open fold' },
    { ']z', desc = 'Go to end of current open fold' },

    {
      'zp',
      function()
        local winid = require('ufo').peekFoldedLinesUnderCursor()
        if not winid then
          vim.lsp.buf.hover()
        end
      end,
      desc = 'Peek folded lines',
    },
  },
}
