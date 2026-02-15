{
  fetchurl,
  stdenv,
  lib,
}:

stdenv.mkDerivation rec {
  pname = "grepai";
  version = "0.31.0";

  src = fetchurl {
    url = "https://github.com/yoanbernabeu/grepai/releases/download/v${version}/grepai_0.31.0_darwin_arm64.tar.gz";
    sha256 = "sha256-24a080471d33ad1033d302acf6145f8e8d051eff89a70e030603681156e1e592";
  };

  unpackPhase = ''
    tar xzf $src
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp grepai $out/bin/grepai
    chmod +x $out/bin/grepai
  '';

  meta = with lib; {
    description = "AI-powered semantic code search tool";
    homepage = "https://github.com/yoanbernabeu/grepai";
    license = licenses.mit;
    mainProgram = "grepai";
    platforms = platforms.darwinArm64;
  };
}
