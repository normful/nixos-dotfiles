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
            table.insert(newVirtText, {chunkText, hlGroup})
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            if curWidth + chunkWidth < targetWidth then
                suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
            end
            break
        end
        curWidth = curWidth + chunkWidth
    end
    table.insert(newVirtText, {suffix, 'MoreMsg'})
    return newVirtText
end

local function configure_nvim_ufo()
  local set = require("utils").set

  set('foldcolumn', '0')
  set('foldlevel', 99)
  set('foldlevelstart', 99)
  set('foldenable', true)

  local ufo = require('ufo')
  ufo.setup({
    provider_selector = function()
      return { 'treesitter', 'indent' }
    end,
    fold_virt_text_handler = fold_virt_text_handler,
  })
end

return {
  'kevinhwang91/nvim-ufo',
  dependencies = {
    { 'kevinhwang91/promise-async', event = 'VeryLazy' },
  },
  lazy = false,
  config = configure_nvim_ufo,

  -- See `:h fold` docs for more folding basics
  keys = {
    { 'zR', function() require('ufo').openAllFolds() end },
    { 'zM', function() require('ufo').closeAllFolds() end },

    { 'zr', function() require('ufo').openFoldsExceptKinds() end },
    { 'zm', function() require('ufo').closeFoldsWith() end },

    { '~', 'za', desc = 'toggle' },
    { 'za' },
    { 'zA' },

    { 'zo' },
    { 'zc' },

    { 'zO' },
    { 'zC' },

    { '[z' },
    { ']z' },

    { 'zp',
      function()
        local winid = require('ufo').peekFoldedLinesUnderCursor()
        if not winid then
          vim.lsp.buf.hover()
        end
      end,
      desc = 'Peek foled lines',
    },
  },
}
