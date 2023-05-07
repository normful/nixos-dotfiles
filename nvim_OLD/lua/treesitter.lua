local function configure_treesitter()
  require('nvim-treesitter.configs').setup({
    highlight = {
      enable = true,
      custom_captures = {
        -- Not sure if this is needed or not...
        ['property_identifier'] = 'TSProperty',
      },
    },
    indent = {
      enable = true,
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = 'gnn',
        node_incremental = 'grn',
        scope_incremental = 'grc',
        node_decremental = 'grm',
      },
    },
    playground = {
      enable = true,
      updatetime = 25,
      persist_queries = false,
      keybindings = {
        toggle_query_editor = 'o',
        toggle_hl_groups = 'i',
        toggle_injected_languages = 't',
        toggle_anonymous_nodes = 'a',
        toggle_language_display = 'I',
        focus_language = 'f',
        unfocus_language = 'F',
        update = 'R',
        goto_node = '<cr>',
        show_help = '?',
      },
    },
    textsubjects = {
      enable = true,
      keymaps = {
        ['v'] = 'textsubjects-smart',
      }
    },
  })

  local set = utils.set
  local o, w, b = vim.o, vim.w, vim.b

  utils.nnoremap_silent_bulk({
    ['<F3>'] = '<Cmd>TSPlaygroundToggle<CR>',
  })

  set('foldmethod', 'expr', {o, wo})
  set('foldexpr', 'nvim_treesitter#foldexpr()')
end

configure_treesitter()
