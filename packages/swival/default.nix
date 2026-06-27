{
  lib,
  fetchFromGitHub,
  python313Packages,
}:

python313Packages.buildPythonApplication rec {
  pname = "swival";
  version = "1.0.34";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "Swival";
    repo = "swival";
    rev = version;
    hash = "sha256-Sx1HIjNGZ4xx18TuzCQkBw6/z+ngKhbfVyuLn8ayqGQ=";
  };

  nativeBuildInputs = with python313Packages; [
    hatchling
  ];

  propagatedBuildInputs = with python313Packages; [
    litellm
    tiktoken
    rich
    prompt-toolkit
    mcp
    rank-bm25
    httpx
    starlette
    uvicorn
    boto3
  ];

  # Missing from nixpkgs-unstable-2611 (install via pip if needed):
  #   html-to-markdown >=3.7.2,<4
  #   fast-cipher >=0.2.2
  #   google-cloud-aiplatform >=1.158.0
  # Some version constraints may not be met:
  #   litellm (nixpkgs: 1.89.0, needs >=1.89.4)
  #   tiktoken (nixpkgs: 0.12.0, needs >=0.13.0)
  #   rich (nixpkgs: 14.3.3, needs >=15.0.0)
  #   mcp (nixpkgs: 1.27.0, needs >=1.28.1)
  #   starlette (nixpkgs: 0.52.1, needs >=1.3.1)
  #   uvicorn (nixpkgs: 0.40.0, needs >=0.49.0)
  #   boto3 (nixpkgs: 1.42.31, needs >=1.43.36)
  dontCheckRuntimeDeps = true;

  meta = with lib; {
    description = "A small, powerful CLI coding agent for open AI models";
    longDescription = ''
      Swival is a CLI coding agent built to be practical, reliable, and easy to use.
      It works with frontier models, but its main goal is to be as reliable as
      possible with smaller models, including local ones. Connects to LM Studio,
      llama.cpp, HuggingFace, OpenRouter, Google Gemini, ChatGPT, AWS Bedrock,
      and any OpenAI-compatible server.
    '';
    homepage = "https://swival.dev/";
    license = licenses.mit;
    mainProgram = "swival";
    platforms = [ "aarch64-darwin" ];
  };
}
