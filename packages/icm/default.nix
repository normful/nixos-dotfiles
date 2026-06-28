{
  lib,
  fetchurl,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "icm";
  version = "0.10.57";

  src = fetchurl {
    url = "https://github.com/rtk-ai/icm/releases/download/icm-v${version}/icm-aarch64-apple-darwin.tar.gz";
    sha256 = "0f3134f4826678419947d4ac47e28b520eb1874d1198ef5b50dc06c7bfe89642";
  };

  dontBuild = true;
  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin
    chmod +x $out/bin/icm
    runHook postInstall
  '';

  meta = with lib; {
    description = "Permanent memory for AI agents — single binary, zero dependencies, MCP native";
    longDescription = ''
      ICM is a CLI and MCP server for persistent agent memory. Sessions are
      captured, compressed into searchable memory entries, and injected as
      context on the next start. Single binary, zero runtime dependencies.
    '';
    homepage = "https://github.com/rtk-ai/icm";
    license = licenses.mit;
    mainProgram = "icm";
    platforms = [ "aarch64-darwin" ];
  };
}
