{
  lib,
  stdenv,
  fetchurl,
}:

let
  pname = "gastown";
  version = "0.5.0";

  # Platform-specific URLs and hashes for gastown v0.5.0
  platforms = {
    x86_64-darwin = {
      url = "https://github.com/steveyegge/gastown/releases/download/v${version}/${pname}_${version}_darwin_amd64.tar.gz";
      hash = "sha256-AdVIBY579r0stW0D06aQ+e1MsOJalBoOSHJGGMb1heU=";
    };
    aarch64-darwin = {
      url = "https://github.com/steveyegge/gastown/releases/download/v${version}/${pname}_${version}_darwin_arm64.tar.gz";
      hash = "sha256-QEPiPYvu0owJ3/reAR3PqntWw5lXRmQ+RKuGy1I5PUY=";
    };
    x86_64-linux = {
      url = "https://github.com/steveyegge/gastown/releases/download/v${version}/${pname}_${version}_linux_amd64.tar.gz";
      hash = "sha256-Q4JFwKyRpC7q1KGxt0S1BaH3BConQjnmWZgPZ7eIZ4A=";
    };
    aarch64-linux = {
      url = "https://github.com/steveyegge/gastown/releases/download/v${version}/${pname}_${version}_linux_arm64.tar.gz";
      hash = "sha256-s9V6PIAikHmusjbcBZsZD+QO4yKQMMpKQ/xH8yu9kUU=";
    };
  };
in
stdenv.mkDerivation {
  inherit pname version;

  src = let
    current = platforms.${stdenv.hostPlatform.system};
  in fetchurl {
    url = current.url;
    sha256 = current.hash;
  };

  nativeBuildInputs = [];
  dontBuild = true;
  dontConfigure = true;
  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/bin
    cp gt $out/bin/

    mkdir -p $out/share/doc/${pname}
    cp README.md $out/share/doc/${pname}/

    mkdir -p $out/share/licenses/${pname}
    cp LICENSE $out/share/licenses/${pname}/
  '';

  meta = with lib; {
    description = "Multi-agent orchestration system for Claude Code with persistent work tracking";
    homepage = "https://github.com/steveyegge/gastown";
    license = licenses.mit;
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "gt";
  };
}
