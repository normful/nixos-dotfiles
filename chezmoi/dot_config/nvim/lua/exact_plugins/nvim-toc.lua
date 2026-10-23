local function configure_nvim_toc()
  require('nvim-toc').setup({
    toc_header = 'Table of Contents',
  })
end

return {
  'richardbizik/nvim-toc',
  config = configure_nvim_toc,
  ft = 'markdown',
}
