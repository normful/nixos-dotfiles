# omp – prebuilt binaries, no nixpkgs package exists
# https://github.com/can1357/oh-my-pi
#
# OMP is a bun-compiled single-file binary (the agent, its TUI, and the
# pi-natives addon are all embedded). Upstream also ships a flake that builds
# from source, but that would drag in bun2nix + rust-overlay + nix-bun and a
# nightly Rust toolchain, so we install the signed release asset instead.
#
# To update to a newer release:
#   1. Bump `version` to the new tag (without the `v`).
#   2. Refresh each hash from the release's SHA256SUMS.txt:
#        curl -sL https://github.com/can1357/oh-my-pi/releases/download/v<version>/SHA256SUMS.txt
#   3. `nix build` this package and smoke-test `result/bin/omp --version`.
{
  lib,
  stdenvNoCC,
  fetchurl,
}: let
  version = "18.10.1";
  base = "https://github.com/can1357/oh-my-pi/releases/download/v${version}";

  # Release assets are bare executables, not archives: `omp-<os>-<arch>`.
  # Darwin only: the Linux assets are dynamically linked ELF with interpreter
  # /lib64/ld-linux-x86-64.so.2 (verified against v18.10.1), so they would need
  # autoPatchelfHook — and patchelf on a `bun --compile` payload is the exact
  # thing that broke OMP upstream (can1357/oh-my-pi issue #9881: growing
  # .dynamic leaves a stale DT_VERDEF and the loader SIGSEGVs). Not worth
  # shipping unverified; add with a real Linux build to test if ever needed.
  sources = {
    aarch64-darwin = {
      url = "${base}/omp-darwin-arm64";
      sha256 = "74d920b72e7af01dbe258b41bb0684da7e747af63628eee41e98b5e74e2f21ac";
    };
    x86_64-darwin = {
      url = "${base}/omp-darwin-x64";
      sha256 = "057b47eb1b3d57c0af9d89c3b144be455d2064e9febdc85bec8a38191302e1d6";
    };
  };

  src = fetchurl sources.${stdenvNoCC.hostPlatform.system};
in
  stdenvNoCC.mkDerivation {
    pname = "omp";
    inherit version src;

    dontBuild = true;
    dontConfigure = true;
    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 $src $out/bin/omp
      runHook postInstall
    '';

    # The asset is Developer ID signed with a hardened runtime; stripping or
    # rewriting it would invalidate the signature and macOS would refuse to
    # exec it. Nothing here needs fixup anyway.
    dontFixup = true;

    meta = with lib; {
      description = "Terminal-based coding agent with multi-model support";
      longDescription = ''
        OMP (oh-my-pi) is a fork of Pi: a terminal coding agent with an IDE-grade
        tool surface. It ships 31 built-in tools plus LSP and DAP integrations,
        talks to 60+ providers, and carries its whole runtime (Bun, TUI,
        pi-natives addon) inside one self-contained binary.
      '';
      homepage = "https://omp.sh";
      changelog = "https://github.com/can1357/oh-my-pi/releases/tag/v${version}";
      license = licenses.mit;
      mainProgram = "omp";
      platforms = builtins.attrNames sources;
      sourceProvenance = with sourceTypes; [binaryNativeCode];
    };
  }
