{ pkgs, ... }:

pkgs.stdenv.mkDerivation rec {
  pname = "gemini-cli";
  version = "0.3.0-nightly.20250823.1a89d185";

  src = pkgs.fetchurl {
    url = "https://github.com/google-gemini/gemini-cli/releases/download/v${version}/gemini.js";
    hash = "sha256-o6VRU9krCzuSrhBOjSP8VHoeCnf+AN6tadovmJ/p1LU=";
  };

  dontUnpack = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    cp $src $out/lib/gemini.js
    chmod +x $out/lib/gemini.js

    mkdir -p $out/bin
    makeWrapper ${pkgs.nodejs_24}/bin/node $out/bin/gemini --add-flags "$out/lib/gemini.js"

    runHook postInstall
  '';

  meta = {
    homepage = "https://github.com/google-gemini/gemini-cli";
    mainProgram = "gemini";
  };
}
