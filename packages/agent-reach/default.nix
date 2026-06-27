{
  lib,
  fetchFromGitHub,
  python314Packages,
}:

python314Packages.buildPythonApplication rec {
  pname = "agent-reach";
  version = "1.5.0";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "Panniantong";
    repo = "Agent-Reach";
    rev = "v${version}";
    hash = "sha256-rCEtsGDa+CzEGavRPKDtjy1SNrUGdrgtq+iWkOaQbIQ=";
  };

  nativeBuildInputs = with python314Packages; [
    hatchling
  ];

  propagatedBuildInputs = with python314Packages; [
    requests
    feedparser
    python-dotenv
    loguru
    pyyaml
    rich
    yt-dlp
  ];

  # Optional deps (not included):
  #   playwright       → browser automation
  #   browser-cookie3  → cookie extraction
  #   mcp[cli]         → MCP integration

  dontCheckRuntimeDeps = true;
  doCheck = false;

  meta = with lib; {
    description = "Give your AI Agent eyes to see the entire internet. Search + Read 10+ platforms.";
    homepage = "https://github.com/Panniantong/agent-reach";
    license = licenses.mit;
    mainProgram = "agent-reach";
    platforms = [ "aarch64-darwin" ];
  };
}
