{
  lib,
  fetchFromGitHub,
  python314Packages,
}:

python314Packages.buildPythonApplication rec {
  pname = "graphifyy";
  version = "0.8.50";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "safishamsi";
    repo = "graphify";
    rev = "v8";
    hash = "sha256-gugoWhYTU27feoLg/5KlUkN13mmFWvaw7JCv6KkbJD4=";
  };

  nativeBuildInputs = with python314Packages; [
    setuptools
    wheel
  ];

  propagatedBuildInputs = with python314Packages; [
    networkx
    numpy
    rapidfuzz
    # Only tree-sitter grammars that exist in nixpkgs;
    # graphifyy installs/builds missing ones at runtime.
    tree-sitter
    tree-sitter-python
    tree-sitter-javascript
    tree-sitter-rust
    tree-sitter-c-sharp
    tree-sitter-json
  ];

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
