{
  lib,
  fetchFromGitHub,
  python312Packages,
}:

python312Packages.buildPythonApplication rec {
  pname = "bernstein";
  version = "2.8.2";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "sipyourdrink-ltd";
    repo = "bernstein";
    rev = "v${version}";
    hash = "sha256-VT/qS+LdCqNgd1ww2XV3iTq50xPxwnqj+e0VCNwJ2kc=";
  };

  nativeBuildInputs = with python312Packages; [
    hatchling
  ];

  propagatedBuildInputs = with python312Packages; [
    fastapi
    starlette
    uvicorn
    httpx
    cryptography
    pyyaml
    rich
    textual
    click
    openai
    pydantic-settings
    python-dotenv
    setproctitle
    prometheus-client
    pluggy
    mcp
    watchdog
    opentelemetry-api
    opentelemetry-sdk
    opentelemetry-exporter-otlp
    pillow
    pyfiglet
    terminaltexteffects
    websockets
    signxml
    defusedxml
    keyring
    jsonschema
    asn1crypto
    reportlab
    python-frontmatter
    idna
  ];

  # Some nixpkgs versions trail upstream constraints:
  #   openai 2.33.0 (< 2.36.0), opentelemetry-* 1.34.0 (< 1.41.1),
  #   pydantic-settings 2.12.0 (< 2.13.1)
  dontCheckRuntimeDeps = true;

  meta = with lib; {
    description = "Audit-grade multi-agent orchestration for CLI coding agents";
    longDescription = ''
      Bernstein is a deterministic Python scheduler that runs a crew of CLI
      coding agents (Claude Code, Codex, Gemini CLI, and 40 more) against a
      single goal in parallel git worktrees, with an HMAC-signed audit chain
      over every step. Features HMAC-SHA256 audit logging, signed agent cards,
      per-artefact lineage, and deterministic scheduling with zero LLM in the
      coordination loop.
    '';
    homepage = "https://github.com/sipyourdrink-ltd/bernstein";
    license = licenses.asl20;
    mainProgram = "bernstein";
    platforms = [ "aarch64-darwin" ];
  };
}
