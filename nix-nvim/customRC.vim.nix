{ pkgs, ... }:

let
  initLazyAndNvChad.lua = builtins.readFile ./initLazyAndNvChad.lua;
in

''
  lua << EOF
    ${initLazyAndNvChad.lua}
  EOF
''
