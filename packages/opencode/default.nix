# opencode – prebuilt binary from GitHub Releases
# https://github.com/anomalyco/opencode
#
# nixpkgs has this package (pkgs/by-name/op/opencode), but it builds from source
# with bun and needs two hashes: a `src` fetchFromGitHub hash plus a
# `node_modules` fixed-output hash that can only be discovered by running
# `bun install --os=* --cpu=*` in the sandbox (multi-GB store output, and one
# deliberately failed build per version bump). The nixpkgs pinned in flake.nix
# is also behind, so no version of it is available here anyway. Installing the
# signed release asset keeps a bump to a version string plus one sha256.
#
# To update to a newer release:
#   1. Bump `version` to the new tag (without the `v`).
#   2. Refresh the hash from the release's SHA256SUMS:
#        curl -sL https://github.com/anomalyco/opencode/releases/download/v<version>/SHA256SUMS \
#          | grep opencode-darwin-arm64.zip
#   3. `nix build` this package and smoke-test `result/bin/opencode --version`.
{
  lib,
  fetchurl,
  makeWrapper,
  ripgrep,
  stdenvNoCC,
  sysctl,
  unzip,
}: let
  version = "2.2.0";

  # Upstream ships four nix-relevant assets (verified against v2.2.0):
  #   - opencode-darwin-arm64.zip / opencode-darwin-x64.zip  (signed Mach-O)
  #   - opencode-linux-{arm64,x64,baseline}.tar.gz           (raw ELF)
  #   - opencode-linux-*-musl.tar.gz
  # Only the Darwin arm64 one is shipped here. The Linux assets are
  # `bun --compile` single-file payloads; autoPatchelfHook grows `.dynamic` and
  # leaves a stale DT_VERDEF, so the loader SIGSEGVs before main()
  # (can1357/oh-my-pi#9881) — not worth shipping an asset we cannot build-test.
  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-darwin-arm64.zip";
    sha256 = "c71b1cd96541539ad38e2a75377d2f43d2a27567289a14371a182e9a0800db3d";
  };
in
  stdenvNoCC.mkDerivation {
    pname = "opencode";
    inherit version src;

    nativeBuildInputs = [
      makeWrapper
      unzip
    ];

    dontBuild = true;
    dontConfigure = true;

    # The zip contains a single file at its root (`opencode`, no directory), so
    # stdenv's unpacker bails with "unpacker appears to have produced no
    # directories". Extract it by hand instead.
    dontUnpack = true;

    # The asset is a single-file `bun --compile` payload, Developer-ID signed
    # with a hardened runtime (TeamIdentifier 5NZ4Q7NXJ4). Strip rewrites the
    # Mach-O and invalidates the embedded signature, after which macOS refuses
    # to exec it, so fixup is skipped entirely.
    dontFixup = true;

    installPhase = ''
      runHook preInstall

      unzip -q $src opencode -d .
      install -Dm755 opencode $out/bin/opencode

      # Mirror what nixpkgs' from-source wrapper sets: disable the self-updater
      # (it would try to write into the read-only store) and put ripgrep on PATH
      # for the agent's grep tool. sysctl is used for host detection on Darwin.
      wrapProgram $out/bin/opencode \
        --set OPENCODE_DISABLE_AUTOUPDATE true \
        --suffix PATH : ${lib.makeBinPath [ripgrep sysctl]}

      runHook postInstall
    '';

    meta = with lib; {
      description = "AI coding agent built for the terminal";
      longDescription = ''
        OpenCode is an agentic coding tool that runs in the terminal. It talks to
        a wide set of model providers, drives file edits and shell commands, and
        carries its whole runtime inside one self-contained Bun binary.
      '';
      homepage = "https://github.com/anomalyco/opencode";
      changelog = "https://github.com/anomalyco/opencode/releases/tag/v${version}";
      license = licenses.mit;
      mainProgram = "opencode";
      platforms = ["aarch64-darwin"];
      sourceProvenance = with sourceTypes; [binaryNativeCode];
    };
  }
