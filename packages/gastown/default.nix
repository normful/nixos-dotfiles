{
  lib,
  stdenvNoDarwin,
  fetchurl,
}:

let
  # Platform-specific URLs and hashes for gastown v0.5.0
  platforms = {
    x86_64-darwin = {
      url = "https://github.com/steveyegge/gastown/releases/download/v${version}/${pname}_${version}_darwin_amd64.tar.gz";
      hash = "sha256-01d548058e7bf6bd2cb56d03d3a690f9ed4cb0e25a941a0e48724618c6f585e5";
    };
    aarch64-darwin = {
      url = "https://github.com/steveyegge/gastown/releases/download/v${version}/${pname}_${version}_darwin_arm64.tar.gz";
      hash = "sha256-4043e23d8beed28c09dffade011dcfaa7b56c3995746643e44ab86cb52393d46";
    };
    x86_64-linux = {
      url = "https://github.com/steveyegge/gastown/releases/download/v${version}/${pname}_${version}_linux_amd64.tar.gz";
      hash = "sha256-438245c0ac91a42eead4a1b1b744b505a1f7042a274239e659980f67b7886780";
    };
    aarch64-linux = {
      url = "https://github.com/steveyegge/gastown/releases/download/v${version}/${pname}_${version}_linux_arm64.tar.gz";
      hash = "sha256-b3d57a3c80229079aeb236dc059b190fe40ee3229030ca4a43fc47f32bbd9145";
    };
  };
in
stdenvNoDarwin.mkDerivation rec {
  pname = "gastown";
  version = "0.5.0";

  src = let
    current = platforms.${stdenvNoDarwin.hostPlatform.system};
  in fetchurl {
    url = current.url;
    sha256 = current.hash;
  };

  nativeBuildInputs = [];
  dontBuild = true;
  dontConfigure = true;

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
