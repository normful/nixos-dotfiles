{
  lib,
  fetchurl,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "lumen";
  version = "2.30.0";

  src = fetchurl {
    url = "https://github.com/jnsahaj/lumen/releases/download/v${version}/lumen-aarch64-apple-darwin.tar.gz";
    sha256 = "6698034790bfce5ae7b7d0c5da00b85dec2f664749eef5e9aca800874dd1f654";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src
    install -m755 lumen $out/bin/lumen
    runHook postInstall
  '';

  meta = with lib; {
    description = "Beautiful git diff viewer, generate commits with AI, get summary of changes — all from the CLI";
    longDescription = ''
      Lumen is a CLI tool for git diff visualization, AI-powered commit
      generation, and change summaries. Provides an interactive, colorful
      terminal UI for reviewing diffs before committing.
    '';
    homepage = "https://github.com/jnsahaj/lumen";
    license = licenses.mit;
    mainProgram = "lumen";
    platforms = [ "aarch64-darwin" ];
  };
}
