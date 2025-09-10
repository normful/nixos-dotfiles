local function configure_nvim_bqf()
  require('bqf').setup({
    auto_enable = true,
    auto_resize_height = false,
  })
end

return {
  'kevinhwang91/nvim-bqf',
  config = configure_nvim_bqf,
}
