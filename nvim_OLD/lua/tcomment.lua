local function configure_tcomment()
  local g = vim.g
  g.tcomment_maps = 0

  local nv_mode_mappings = {
    ['<Leader>cl'] = ':TComment<CR>',
    ['<Leader>cb'] = ':TCommentBlock<CR>',
  }

  utils.nnoremap_silent_bulk(nv_mode_mappings)
  utils.xnoremap_silent_bulk(nv_mode_mappings)
end

configure_tcomment()
