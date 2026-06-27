{
  lib,
  fetchFromGitHub,
  python314Packages,
}:

python314Packages.buildPythonApplication {
  pname = "skillspector";
  version = "0-unstable-2026-06-10";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "SkillSpector";
    rev = "1a7bf02";
    hash = "sha256-NwkfzgKfKNC9xWoznCRfdFrytvdR+J5X7TImdjZ6Td8=";
  };

  nativeBuildInputs = with python314Packages; [
    hatchling
  ];

  propagatedBuildInputs = with python314Packages; [
    typer
    rich
    httpx
    pyyaml
    pydantic
    openai
    langgraph
    langgraph-cli
    langchain-core
    langchain-openai
    langsmith
    yara-python
  ];

  # All deps are listed above — keep this flag in case nixpkgs lags
  # behind upstream dep additions.
  dontCheckRuntimeDeps = true;

  meta = with lib; {
    description = "Security scanner for AI agent skills — detects vulnerabilities before you install";
    homepage = "https://github.com/NVIDIA/SkillSpector";
    license = licenses.mit;
    mainProgram = "skillspector";
    platforms = [ "aarch64-darwin" ];
  };
}
