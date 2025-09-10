{ pkgs, ... }:

let
  initLazyAndNvChad = builtins.readFile ./initLazyAndNvChad.lua;
in

''
  lua << EOF
    ${initLazyAndNvChad}
  EOF
''
