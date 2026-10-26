{
  lib,
  fetchurl,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "agent-browser";
  version = "0.38.2";

  src = fetchurl {
    url = "https://github.com/vercel-labs/agent-browser/releases/download/v${version}/agent-browser-darwin-arm64";
    sha256 = "8168b86ab5d94be8f670992dfe4fe1445016518a864b48bda105e64142e7cbf9";
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
