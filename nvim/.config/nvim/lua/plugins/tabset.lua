local function configure_tabset()
  local tabset = require("tabset")
  tabset.setup({
    defaults = {
      tabwidth = 2,
      expandtab = 2,
    },
  })
end

return {
  'FotiadisM/tabset.nvim',
  config = configure_tabset,
  lazy = false,
}
