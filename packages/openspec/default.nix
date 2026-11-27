# openspec – prebuilt standalone binary, pinned ahead of nixpkgs (1.16.0)
# https://github.com/Fission-AI/OpenSpec
#
# Upstream compiles this with `bun build --compile`. The schemas the CLI needs
# are baked into the executable at build time (scripts/binary/build.mjs defines
# OPENSPEC_EMBEDDED_SCHEMAS), so the tarball's only other file is LICENSE and
# nothing else needs installing.
#
# To update:
#   1. Bump `version` to the new tag (without the `v`).
#   2. Refresh the hash from
#        curl -sL https://github.com/Fission-AI/OpenSpec/releases/download/v<version>/SHA256SUMS
#   3. nix build, then `result/bin/openspec --version`.
#
# aarch64-darwin only: upstream also ships darwin-x64 and glibc/musl Linux
# assets, but neither can be executed on this machine to verify them, and the
# Linux ones are `bun --compile` ELF that would need autoPatchelfHook — the
# exact thing that breaks a bun payload (see packages/omp/default.nix).
{
  lib,
  stdenvNoCC,
  fetchurl,
}: let
  version = "2.2.0";
in
  stdenvNoCC.mkDerivation {
    pname = "openspec";
    inherit version;

    src = fetchurl {
      url = "https://github.com/Fission-AI/OpenSpec/releases/download/v${version}/openspec-darwin-arm64.tar.gz";
      sha256 = "d46a773862f31c317f221e52045767fd132c87cf839b800e6728e975b2a5842a";
    };

    dontBuild = true;
    dontConfigure = true;
    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      tar -xzf $src -C $out/bin openspec
      chmod 755 $out/bin/openspec
      runHook postInstall
    '';

    # The asset is an adhoc, linker-signed arm64 Mach-O. Fixup's strip would
    # invalidate that signature and macOS would refuse to exec it.
    dontFixup = true;

    meta = with lib; {
      description = "AI-native system for spec-driven development";
      longDescription = ''
        OpenSpec is a spec-driven development (SDD) workflow for AI coding
        assistants: proposals, delta specs, and validation, driven from the
        terminal. This is upstream's standalone release build, which carries
        its own Bun runtime and the workflow schemas embedded, so it needs no
        Node.js.
      '';
      homepage = "https://github.com/Fission-AI/OpenSpec";
      changelog = "https://github.com/Fission-AI/OpenSpec/releases/tag/v${version}";
      license = licenses.mit;
      mainProgram = "openspec";
      platforms = ["aarch64-darwin"];
      sourceProvenance = with sourceTypes; [binaryNativeCode];
    };
  }
