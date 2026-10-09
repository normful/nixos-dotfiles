# aven – prebuilt binaries, no nixpkgs package exists
# https://github.com/raine/aven
{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.1.46";
  base = "https://github.com/raine/aven/releases/download/v${version}";

  sources = {
    aarch64-darwin = {
      url = "${base}/aven-darwin-arm64.tar.gz";
      sha256 = "9228aa2f854595628032a5ca1370c51818b0bd9c82f37ecd3c77fe68a5ff7283";
    };
    x86_64-darwin = {
      url = "${base}/aven-darwin-amd64.tar.gz";
      sha256 = "a26341c87053e0aa28d99ac351fe05307a619fe54f7cd6d6e6d96a95c6671bbd";
    };
    aarch64-linux = {
      url = "${base}/aven-linux-arm64.tar.gz";
      sha256 = "9a11ed354b02acf37fab1064fb08b73b16edcc76b16408a23568c963f7326d88";
    };
    x86_64-linux = {
      url = "${base}/aven-linux-amd64.tar.gz";
      sha256 = "e1a72cb4b64d12d9f421a9b2bc845f6f2df3311c2c80a419cc429cc3bc055644";
    };
  };

  src = fetchurl sources.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "aven";
  inherit version src;

  dontBuild = true;
  dontConfigure = true;
  dontUnpack = true;

  # Archive contains a single statically linked binary named `aven`.
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin aven
    chmod +x $out/bin/aven
    runHook postInstall
  '';

  meta = with lib; {
    description = "Local-first task manager for power users and agents";
    longDescription = ''
      Aven is a local-first task manager built for power users and AI agents.
      Tasks live in a local SQLite database; projects and workspaces are
      inferred from the current directory, and a CLI plus agent workflows
      cover listing, searching, refs, and status transitions.
    '';
    homepage = "https://github.com/raine/aven";
    changelog = "https://github.com/raine/aven/releases/tag/v${version}";
    license = licenses.mit;
    mainProgram = "aven";
    platforms = builtins.attrNames sources;
  };
}
