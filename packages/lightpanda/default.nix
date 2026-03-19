{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

let
  version = "0.2.6";

  sources = {
    aarch64-darwin = {
      url = "https://github.com/lightpanda-io/browser/releases/download/v${version}/lightpanda-aarch64-macos";
      hash = "sha256-6fdqFy/XAQi1sj8S0qC0LjfDbfaszOXoD8OVhc4/lcE=";
    };
  };

  src = fetchurl sources.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "lightpanda";
  inherit version;
  inherit src;

  dontUnpack = true;

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/lightpanda
    runHook postInstall
  '';

  meta = {
    description = "Headless browser designed for AI and automation";
    homepage = "https://github.com/lightpanda-io/browser";
    license = lib.licenses.agpl3Only;
    platforms = builtins.attrNames sources;
    mainProgram = "lightpanda";
  };
}
