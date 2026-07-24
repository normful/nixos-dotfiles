{
  lib,
  fetchurl,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "codecanary";
  version = "0.6.24";

  src = fetchurl {
    url = "https://github.com/alansikora/codecanary/releases/download/v${version}/codecanary_${version}_darwin_arm64.tar.gz";
    sha256 = "5ffe530af2f2e5e737921543beb39988047fbccecbe2de9ff9d26b5031e5e341";
  };

  dontBuild = true;
  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    tar -xzf $src
    install -m755 codecanary $out/bin/codecanary
  '';

  meta = with lib; {
    description = "AI-powered code review for GitHub pull requests";
    longDescription = ''
      CodeCanary is an AI-powered code review tool for GitHub pull requests.
      It catches bugs, security issues, and quality problems before they land in main.
      Supports multiple LLM providers (Anthropic, OpenAI, OpenRouter, Grok, Claude CLI)
      and provides incremental reviews, conversational thread resolution, and native PR integration.
    '';
    homepage = "https://github.com/alansikora/codecanary";
    license = licenses.mit;
    mainProgram = "codecanary";
    platforms = [ "aarch64-darwin" ];
  };
}
