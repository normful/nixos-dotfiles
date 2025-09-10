local function is_likely_api_key(word)
  local lc_word = word:lower()

  -- Check 1: Keywords (Case-insensitive)
  local keywords = { 'api_key', 'apikey', 'secret', 'token', 'password', 'auth', 'credential', '_key_', '_secret_', '_token_' }
  for _, keyword in ipairs(keywords) do
    if string.find(lc_word, keyword, 1, true) then
      return true
    end
  end

  -- Check 2: Prefixes (Case-insensitive)
  if lc_word:match('^sk_') or lc_word:match('^pk_') or lc_word:match('^ghp_') or lc_word:match('^glpat-') then
    return true
  end

  -- Check 3: Structure (Long alphanumeric with mix of chars, or long hex)
  -- Only check structure if it's reasonably long to avoid filtering normal variables
  local min_key_length = 24 -- Increased threshold for combined check
  if #word >= min_key_length then
    -- Long Alphanumeric/Underscore with mixed types?
    if word:match('^[A-Za-z0-9_]+$') and word:match('%d') and word:match('%a') then
      -- Maybe check for mix of upper and lower case too?
      if word:match('%u') and word:match('%l') then
        return true
      end
    end
    -- Long Hex?
    if word:match('^[a-fA-F0-9]+$') then
      return true
    end
  end

  return false
end

return {
  'hrsh7th/nvim-cmp',
  dependencies = {
    { 'hrsh7th/cmp-nvim-lsp-signature-help', event = 'InsertEnter' },
    { 'hrsh7th/cmp-nvim-lsp-document-symbol', event = 'InsertEnter' },
    { 'hrsh7th/cmp-cmdline', event = 'InsertEnter' },
    { 'hrsh7th/cmp-emoji', event = 'InsertEnter' },
    { 'rcarriga/cmp-dap', event = 'InsertEnter' },
    { 'SergioRibera/cmp-dotenv', event = 'InsertEnter' },
    { 'Snikimonkd/cmp-go-pkgs', event = 'InsertEnter' },
    {
      'windwp/nvim-autopairs',
      -- Included by NvChad in https://github.com/NvChad/NvChad/blob/29ebe31ea6a4edf351968c76a93285e6e108ea08/lua/nvchad/plugins/init.lua#L119-L132
      -- But it seems to be buggy, so I'm forcing it to disable here
      enabled = false,
    },
  },

  ---@param conf cmp.ConfigSchema
  opts = function(_, conf)
    local cmp = require('cmp')

    -- Mappings already defined by NvChad: https://github.com/NvChad/NvChad/blob/v2.5/lua/nvchad/configs/cmp.lua
    --[[
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.close(),
    ["<CR>"] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Insert,
      select = true,
    },
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif require("luasnip").expand_or_jumpable() then
        require("luasnip").expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif require("luasnip").jumpable(-1) then
        require("luasnip").jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
    ]]

    conf.mapping['<C-d>'] = nil
    conf.mapping['<C-f>'] = nil

    conf.mapping['<F14>'] = cmp.mapping.scroll_docs(-4) -- Wezterm sends this for CMD+u
    conf.mapping['<F13>'] = cmp.mapping.scroll_docs(4) -- Wezterm sends this for CMD+d

    conf.preselect = cmp.PreselectMode.None

    --- https://github.com/hrsh7th/nvim-cmp/blob/059e89495b3ec09395262f16b1ad441a38081d04/lua/cmp/types/cmp.lua#L168C1-L177
    conf.sources = cmp.config.sources({
      { name = 'nvim_lsp', priority = 100 },
      { name = 'nvim_lsp_signature_help', priority = 90 },
      { name = 'luasnip', priority = 30 },
    }, {
      { name = 'buffer', priority = 50, keyword_length = 3, max_item_count = 5 },
      { name = 'path', priority = 40 },
      {
        name = 'dotenv',
        priority = 35,
        entry_filter = function(entry)
          return not is_likely_api_key(entry.word)
        end,
      },
      { name = 'emoji', priority = 10, max_item_count = 5 },
    })

    cmp.setup.cmdline({ '/', '?' }, {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = 'nvim_lsp_document_symbol' },
        { name = 'buffer' },
      }),
    })

    cmp.setup.cmdline(':', {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = 'path', keyword_length = 3 },
        { name = 'cmdline', keyword_length = 3 },
      }),
      matching = { disallow_symbol_nonprefix_matching = true },
    })

    cmp.setup.filetype({ 'dap-repl', 'dapui_watches', 'dapui_hover' }, {
      sources = cmp.config.sources({
        { name = 'dap' },
      }),
    })

    cmp.setup.filetype({ 'lua' }, {
      sources = cmp.config.sources({
        { name = 'nvim_lua' },
      }),
    })

    cmp.setup.filetype({ 'go' }, {
      sources = cmp.config.sources({
        { name = 'go_pkgs' },
      }),
    })

    return conf
  end,
}
