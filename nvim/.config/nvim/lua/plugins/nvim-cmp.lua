local function configure_nvim_cmp()
  local lspkind = require('lspkind')

  local cmp = require('cmp')
  cmp.setup({
    preselect = cmp.PreselectMode.None,

    window = {
      documentation = {
        max_height = 15,
        max_width = 60,
      },
    },

    mapping = cmp.mapping.preset.insert({
      -- NOTE(norman): Don't add any [Esc] mappings here because it makes exiting from INSERT mode by pressing Esc more unreliable.
      ['<Tab>'] = function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        else
          fallback()
        end
      end,
      ['<S-Tab>'] = function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        else
          fallback()
        end
      end,
      ['<CR>'] = cmp.mapping.confirm({ select = true }),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<C-d>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
    }),

    sorting = {
      comparators = {
        cmp.config.compare.score,
        cmp.config.compare.offset,
        cmp.config.compare.exact,
        cmp.config.compare.scopes,
        cmp.config.compare.recently_used,
        cmp.config.compare.locality,
        cmp.config.compare.kind,
        cmp.config.compare.sort_text,
        cmp.config.compare.length,
        cmp.config.compare.order,
      },
    },

    sources = cmp.config.sources({
      { name = 'nvim_lsp', keyword_length = 0 },
      { name = 'path' },
      { name = 'buffer', keyword_length = 3, max_item_count = 5 },
      { name = 'filename' },
    }),

    completion = {
      keyword_length = 1,
      completeopt = 'menu,menuone,noinsert,noselect',
    },

    view = {
      entries = 'custom',
    },

    formatting = {
      format = lspkind.cmp_format({
        mode = 'symbol',
        maxwidth = 50,
        ellipsis_char = '...',
      }),
    },

    experimental = {
      ghost_text = true,
    },
  })
end

return {
  'hrsh7th/nvim-cmp',
  dependencies = {
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-cmdline',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-nvim-lsp-document-symbol',
    'hrsh7th/cmp-nvim-lua',
    'hrsh7th/cmp-path',
    'onsails/lspkind-nvim',
  },
  config = configure_nvim_cmp,
  event = 'VeryLazy',
}
