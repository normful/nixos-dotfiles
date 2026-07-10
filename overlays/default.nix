# Overlays entry point: auto-discovers subdirectories and composes them.
#
# Each subdirectory under overlays/ with a default.nix is an overlay
# that modifies or extends the nixpkgs package set. This module loads
# all such overlays and composes them into a single overlay function
# that flake.nix applies to the system's nixpkgs config.
#
# How it works:
# 1. readDir lists immediate subdirectories (e.g. figlet-patched/, hello-wrapped-config/)
# 2. Each subdir's default.nix is imported — it must return an overlay
#    function of the form `final: prev: { <new-or-overridden-packages> }`
# 3. composeManyExtensions chains them left-to-right, so the first overlay's
#    overrides are visible to the next via `final`, and each `prev` sees
#    what the preceding overlay(s) produced.
#
# Convention: overlay subdirectories may include a tests/ folder with
# updated test fixtures when the overlay changes test-relevant behavior.
{ lib }:
let
  inherit (builtins) readDir;
  # Filter to only directories (skip default.nix itself, patches/, tests/)
  overlayDirs = lib.filterAttrs (name: type: type == "directory") (readDir ./.);
in

lib.composeManyExtensions (lib.mapAttrsToList (name: _: import ./${name}/default.nix) overlayDirs)
