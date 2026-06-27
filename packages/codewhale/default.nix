{
  lib,
  fetchurl,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "codewhale";
  version = "0.8.65";

  src = fetchurl {
    url = "https://github.com/Hmbown/CodeWhale/releases/download/v${version}/codewhale-macos-arm64.tar.gz";
    sha256 = "4e91b8ee242ceb94c5ab7e139075172f2a44c1366be443a0954a651c0f3674bc";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src
    install -m755 codewhale-macos-arm64/codewhale $out/bin/codewhale
    install -m755 codewhale-macos-arm64/codewhale-tui $out/bin/codewhale-tui
    install -m755 codewhale-macos-arm64/codew $out/bin/codew
    runHook postInstall
  '';

  meta = with lib; {
    description = "Terminal coding agent for any model — open models first";
    longDescription = ''
      CodeWhale is a terminal coding agent — a TUI and a CLI. Point it at a
      model and a project, and it gets to work: reading code, making edits,
      running commands, checking results, planning multi-step tasks, and
      correcting itself when something fails. Open source (MIT, Rust), runs
      on your machine, works with DeepSeek, Claude, GPT, and open-weight
      models via vLLM/SGLang/Ollama.
    '';
    homepage = "https://github.com/Hmbown/CodeWhale";
    license = licenses.mit;
    mainProgram = "codewhale";
    platforms = [ "aarch64-darwin" ];
  };
}
