# aven – prebuilt binaries, no nixpkgs package exists
# https://github.com/raine/aven
{
  lib,
  stdenvNoCC,
  fetchurl,
}: let
  version = "0.1.51";
  base = "https://github.com/raine/aven/releases/download/v${version}";

  sources = {
    aarch64-darwin = {
      url = "${base}/aven-darwin-arm64.tar.gz";
      sha256 = "713fc5dd6c3ee58de025fa045c7078720e02eb5bb43b4748fbb74040a5f2f159";
    };
    x86_64-darwin = {
      url = "${base}/aven-darwin-amd64.tar.gz";
      sha256 = "488aaec4992f669865471a13f2aef653aed2af42d719aa6dea5ebb074d11f2b3";
    };
    aarch64-linux = {
      url = "${base}/aven-linux-arm64.tar.gz";
      sha256 = "520b89360d214f04f480666caf68f149175e91302731cfd888f43aa0d4dd6bbd";
    };
    x86_64-linux = {
      url = "${base}/aven-linux-amd64.tar.gz";
      sha256 = "7f8cfc42e7308745a9cb66953b7fb7c752fd5d9863781e2be7d6b2b01ba7a757";
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
