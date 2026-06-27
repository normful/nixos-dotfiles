{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  nodejs,
}:

buildNpmPackage rec {
  pname = "codegraph";
  version = "1.1.1";

  src = fetchFromGitHub {
    owner = "colbymchenry";
    repo = "codegraph";
    rev = "7a361ef16eee63ec61585c76aff6e2f7742211c0";
    hash = "sha256-08vEZe0N0lsAcHe0686GUhrqNVrMuKUVrIovp/baSoA=";
  };

  npmDepsHash = "sha256-SQmYRcDW/JDVVJ7fWW/FbVwxf1zBY9RVVsbIBnvrEU0=";

  nodejs = nodejs;

  meta = with lib; {
    description = "Supercharge AI coding agents with semantic code intelligence";
    longDescription = ''
      CodeGraph gives AI coding agents a pre-indexed knowledge graph — symbol
      relationships, call graphs, and code structure. Agents query the graph
      instantly instead of scanning files. ~35% cheaper, ~70% fewer tool calls,
      100% local. Supports Claude Code, Cursor, Codex CLI, OpenCode, and
      Hermes Agent.
    '';
    homepage = "https://github.com/colbymchenry/codegraph";
    license = licenses.mit;
    mainProgram = "codegraph";
    platforms = [ "aarch64-darwin" ];
  };
}
