{
  lib,
  fetchFromGitHub,
  rustPlatform,
  openssl,
  pkg-config,
  perl,
  python3,
}:

rustPlatform.buildRustPackage rec {
  pname = "maki";
  version = "0.3.21";

  src = fetchFromGitHub {
    owner = "tontinton";
    repo = "maki";
    rev = "v${version}";
    hash = "sha256-zfWuTduK/SjfuvD3wzfjOrWiPAnemaxapt3Hwr3qWoM=";
  };

  cargoHash = "";

  cargoBuildFlags = [
    "--package"
    pname
  ];

  nativeBuildInputs = [
    pkg-config
    perl
    python3
  ];

  buildInputs = [
    openssl
  ];

  # Upstream monty includes a relative README path that doesn't survive
  # nix vendoring. Remove once monty stops including the relative path.
  postPatch = ''
    for f in "$cargoDepsCopy"/monty-*/src/lib.rs; do
      substituteInPlace "$f" \
        --replace-fail '#![doc = include_str!("../../../README.md")]' \
                       '#![doc = "Monty Python bridge."]'
    done
  '';

  doCheck = false;

  meta = with lib; {
    description = "AI coding agent. Native Rust TUI. Immediate startup, 60 FPS, low memory.";
    longDescription = ''
      Maki is an AI coding agent optimized for minimal context token usage.
      Features tree-sitter code indexing, sandboxed code execution via monty,
      subagent task delegation, fuzzy search, SSRF protection, plan mode,
      skills & MCPs, and 26 themes. Supports Anthropic, OpenAI, Google,
      Copilot, Ollama, llama.cpp, Mistral, DeepSeek, OpenRouter, and more.
    '';
    homepage = "https://maki.sh";
    license = licenses.mit;
    mainProgram = "maki";
    platforms = [ "aarch64-darwin" ];
  };
}
