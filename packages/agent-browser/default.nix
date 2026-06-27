{
  lib,
  fetchurl,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "agent-browser";
  version = "0.31.1";

  src = fetchurl {
    url = "https://github.com/vercel-labs/agent-browser/releases/download/v${version}/agent-browser-darwin-arm64";
    sha256 = "fd7acd17b3071ff7f75a03c1ecd30501959d9c2d063bdaa05adb6f77abf2a7bf";
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
    platforms = [ "aarch64-darwin" ];
  };
}
