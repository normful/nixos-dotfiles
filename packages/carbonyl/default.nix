{
  fetchurl,
  stdenv,
  unzip,
  darwin,
  lib,
  makeWrapper,
}:
stdenv.mkDerivation rec {
  pname = "carbonyl";
  version = "0.0.3";

  src = fetchurl {
    url = "https://github.com/fathyb/carbonyl/releases/download/v${version}/carbonyl.macos-arm64.zip";
    sha256 = "0r40v6pfmya1ppqk11abz33r9l6q6nzyw04xzyl99snqcir1kycc";
  };

  nativeBuildInputs = [
    unzip
    makeWrapper
  ]
  ++ lib.optionals stdenv.isDarwin [ darwin.cctools ];

  unpackPhase = "unzip $src";

  installPhase = ''
    mkdir -p $out/libexec/carbonyl
    cp -r carbonyl-*/* $out/libexec/carbonyl/

    # Fix dylib paths on macOS
    ${lib.optionalString stdenv.isDarwin ''
      install_name_tool -change @executable_path/libcarbonyl.dylib $out/libexec/carbonyl/libcarbonyl.dylib $out/libexec/carbonyl/carbonyl
      install_name_tool -change @executable_path/libEGL.dylib $out/libexec/carbonyl/libEGL.dylib $out/libexec/carbonyl/carbonyl
      install_name_tool -change @executable_path/libGLESv2.dylib $out/libexec/carbonyl/libGLESv2.dylib $out/libexec/carbonyl/carbonyl
    ''}

    # Create wrapper to run from the correct directory
    mkdir -p $out/bin
    makeWrapper $out/libexec/carbonyl/carbonyl $out/bin/carbonyl \
      --run "cd $out/libexec/carbonyl"
  '';
}
