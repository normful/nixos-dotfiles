{
  lib,
  fetchFromGitHub,
  python312Packages,
}:

python312Packages.buildPythonApplication rec {
  pname = "graphifyy";
  version = "0.8.50";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "safishamsi";
    repo = "graphify";
    rev = "v8";
    hash = "sha256-gugoWhYTU27feoLg/5KlUkN13mmFWvaw7JCv6KkbJD4=";
  };

  nativeBuildInputs = with python312Packages; [
    setuptools
    wheel
  ];

  propagatedBuildInputs = with python312Packages; [
    networkx
    numpy
    rapidfuzz
    tree-sitter
    tree-sitter-python
    tree-sitter-javascript
    tree-sitter-typescript
    tree-sitter-go
    tree-sitter-rust
    tree-sitter-java
    tree-sitter-groovy
    tree-sitter-c
    tree-sitter-cpp
    tree-sitter-ruby
    tree-sitter-c-sharp
    tree-sitter-kotlin
    tree-sitter-scala
    tree-sitter-php
    tree-sitter-swift
    tree-sitter-lua
    tree-sitter-zig
    tree-sitter-powershell
    tree-sitter-elixir
    tree-sitter-objc
    tree-sitter-julia
    tree-sitter-verilog
    tree-sitter-fortran
    tree-sitter-bash
    tree-sitter-json
  ];

  # Many tree-sitter grammars are not packaged in nixpkgs;
  # graphifyy installs/builds missing ones on first run.
  dontCheckRuntimeDeps = true;

  meta = with lib; {
    description = "Turn any folder into a queryable knowledge graph for AI coding assistants";
    longDescription = ''
      AI coding assistant skill — turn any folder of code, docs, papers, images,
      or videos into a queryable knowledge graph. Supports Claude Code, CodeBuddy,
      Codex, OpenCode, Kilo Code, Cursor, Gemini CLI, Aider, and more.
    '';
    homepage = "https://github.com/safishamsi/graphify";
    license = licenses.mit;
    mainProgram = "graphify";
    platforms = [ "aarch64-darwin" ];
  };
}
