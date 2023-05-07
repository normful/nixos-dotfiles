{ pkgs, ... }:

let
  initLazy.lua = builtins.readFile ./initLazy.lua;
in

''
  lua << EOF
    require("general_settings")
    require("general_maps")
    ${initLazy.lua}
    require("general_commands")
    require("general_augroups")
    require("git_settings")
  EOF
''
