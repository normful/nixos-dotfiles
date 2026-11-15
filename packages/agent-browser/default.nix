{
  lib,
  fetchurl,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "agent-browser";
  version = "0.43.0";

  src = fetchurl {
    url = "https://github.com/vercel-labs/agent-browser/releases/download/v${version}/agent-browser-darwin-arm64";
    sha256 = "05338a8eeddf0b3f9ebf0c87a6c21aedc10685608c68618e1a8483c43eae9c3f";
  };

  dontBuild = true;
  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp $src $out/bin/agent-browser
    chmod +x $out/bin/agent-browser
    runHook postInstall
  '';

  meta = with lib; {
    description = "Fast browser automation CLI for AI agents";
    longDescription = ''
      agent-browser is a fast, native browser automation CLI designed for AI agents.
      It connects to Chrome DevTools Protocol (CDP) to control browsers for web
      scraping, form filling, screenshotting, and more. Supports local and remote
      browser instances.
    '';
    homepage = "https://github.com/vercel-labs/agent-browser";
    license = licenses.asl20;
    mainProgram = "agent-browser";
    platforms = ["aarch64-darwin"];
  };
}
