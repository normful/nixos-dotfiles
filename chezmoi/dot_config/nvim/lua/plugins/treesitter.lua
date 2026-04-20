return {
  'MeanderingProgrammer/treesitter-modules.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    {
      'nvim-treesitter/nvim-treesitter',
      branch = 'main',
      build = ':TSUpdate',
      dependencies = {
        'windwp/nvim-ts-autotag',
        'nvim-treesitter/nvim-treesitter-textobjects',
      },
    },
  },
  opts = {
    auto_install = true,
    sync_install = true,
    ensure_installed = {
      'bash', 'blade', 'c', 'cpp', 'css', 'dockerfile', 'editorconfig',
      'erlang', 'fish', 'git_config', 'git_rebase', 'gitattributes',
      'gitcommit', 'gitignore', 'gleam', 'go', 'gomod', 'gosum', 'gotmpl',
      'graphql', 'groovy', 'helm', 'html', 'hurl', 'java', 'javascript',
      'jsdoc', 'json', 'json5', 'latex', 'lua', 'make', 'markdown_inline',
      'nginx', 'nix', 'php', 'python', 'regex', 'ron', 'ruby',
      'rust', 'scss', 'sql', 'ssh_config', 'svelte', 'terraform', 'toml',
      'tsx', 'typescript', 'typst', 'vim', 'yaml',
    },
    highlight = { enable = true },
    indent = { enable = true },
    fold = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<C-space>',
        node_incremental = '<Space>',
        node_decremental = '<BS>',
      },
    },
  },
  config = function(_, opts)
    require('treesitter-modules').setup(opts)
    require('nvim-ts-autotag').setup()
    require('nvim-treesitter-textobjects').setup({
      move = { set_jumps = false },
      select = { lookahead = true },
    })
    vim.opt.foldmethod = 'expr'
    vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  end,
}
