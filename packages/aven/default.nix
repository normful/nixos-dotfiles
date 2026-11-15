# aven – prebuilt binaries, no nixpkgs package exists
# https://github.com/raine/aven
{
  lib,
  stdenvNoCC,
  fetchurl,
}: let
  version = "0.1.56";
  base = "https://github.com/raine/aven/releases/download/v${version}";

  sources = {
    aarch64-darwin = {
      url = "${base}/aven-darwin-arm64.tar.gz";
      sha256 = "81db92daddcef649d4fdd991b0134669d673efa6377c9f3010b15a28e41d44c7";
    };
    x86_64-darwin = {
      url = "${base}/aven-darwin-amd64.tar.gz";
      sha256 = "1b4558eae823e329bde0feff60ea8b57891544df4150a6c5bde305a4077395ab";
    };
    aarch64-linux = {
      url = "${base}/aven-linux-arm64.tar.gz";
      sha256 = "f8e36e9ef62642fa62f5a1999acafcd4bb15a11686995f23ea2b518a17f4057f";
    };
    x86_64-linux = {
      url = "${base}/aven-linux-amd64.tar.gz";
      sha256 = "ec3a8066aaa2e014bc40bd30973b9f7a8603b262efa33690f407ded00238cbb1";
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
