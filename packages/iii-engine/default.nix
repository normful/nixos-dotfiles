{
  lib,
  fetchurl,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "iii-engine";
  version = "0.11.2";

  src = fetchurl {
    url = "https://github.com/iii-hq/iii/releases/download/iii/v${version}/iii-aarch64-apple-darwin.tar.gz";
    sha256 = "e7834c44fefb2b5343d327102a941419245f7fff447f95373857a04b033fb1bd";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin iii
    chmod +x $out/bin/iii
    runHook postInstall
  '';

  dontFixup = true;

  meta = with lib; {
    description = "iii-engine runtime for agentmemory and iii-based apps";
    longDescription = ''
      iii-engine is the runtime that powers agentmemory and other
      iii-based applications. It provides function triggers, state
      management, streams, and WebSocket-based coordination.
    '';
    homepage = "https://github.com/iii-hq/iii";
    license = licenses.asl20;
    mainProgram = "iii";
    platforms = [ "aarch64-darwin" ];
  };
}
