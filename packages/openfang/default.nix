{
  lib,
  fetchurl,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "openfang";
  version = "0.6.9";

  src = fetchurl {
    url = "https://github.com/RightNow-AI/openfang/releases/download/v${version}/openfang-aarch64-apple-darwin.tar.gz";
    sha256 = "1b77c4a061719d3eebaaa2da45cfaebc5c7096799bc8682d4a8d4ba8893f8e25";
  };

  dontBuild = true;
  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin openfang
    chmod +x $out/bin/openfang
    runHook postInstall
  '';

  meta = with lib; {
    description = "Open-source Agent Operating System — deploy, manage, and orchestrate AI agents from your terminal";
    longDescription = ''
      OpenFang is an open-source Agent Operating System built in Rust.
      40 channels, 60 skills, 50+ models. Runs autonomous agents on schedules,
      24/7 — building knowledge graphs, monitoring targets, generating leads,
      managing social media, and reporting results to a dashboard.
      Single ~32MB binary, one command to get started.
    '';
    homepage = "https://github.com/RightNow-AI/openfang";
    license = licenses.mit;
    mainProgram = "openfang";
    platforms = [ "aarch64-darwin" ];
  };
}
