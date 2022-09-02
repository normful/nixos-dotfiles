{ pkgs, ... }:

let
  init.vim        = builtins.readFile ./vim/init.vim;
  statusline.vim  = builtins.readFile ./vim/statusline.vim;
  projections.vim = builtins.readFile ./vim/projections.vim;
in

''
  ${init.vim}
  ${statusline.vim}
  ${projections.vim}

  lua << EOF
  ${builtins.readFile ./lua/utils.lua}
  ${builtins.readFile ./lua/globals.lua}

  ${builtins.readFile ./lua/general_settings.lua}
  ${builtins.readFile ./lua/general_maps.lua}
  ${builtins.readFile ./lua/general_commands.lua}
  ${builtins.readFile ./lua/general_augroups.lua}

  ${builtins.readFile ./lua/lsp-config.lua}
  ${builtins.readFile ./lua/nvim-tree.lua}
  ${builtins.readFile ./lua/telescope.lua}
  ${builtins.readFile ./lua/vista.lua}
  ${builtins.readFile ./lua/cmdalias.lua}
  ${builtins.readFile ./lua/async-run.lua}
  ${builtins.readFile ./lua/git.lua}
  ${builtins.readFile ./lua/git-messenger.lua}
  ${builtins.readFile ./lua/gitsigns.lua}
  ${builtins.readFile ./lua/tcomment.lua}
  ${builtins.readFile ./lua/treesitter.lua}
  EOF
''
