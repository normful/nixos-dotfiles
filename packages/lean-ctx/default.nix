# lean-ctx – prebuilt binary, no nixpkgs package exists
# https://github.com/yvgude/lean-ctx
#
# Upstream ships prebuilt release assets, so we install the tarball instead of
# compiling the Rust workspace (which needed a feature-list pin and a slow
# jemalloc-free build). The asset is a single bare `lean-ctx` Mach-O.
#
# To update to a newer release:
#   1. Bump `version` to the new tag (without the `v`).
#   2. Refresh the hash from the release's SHA256SUMS:
#        curl -sL https://github.com/yvgude/lean-ctx/releases/download/v<version>/SHA256SUMS
#   3. `nix build` this package and smoke-test `result/bin/lean-ctx --version`.
{
  lib,
  fetchurl,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "lean-ctx";
  version = "3.12.5";

  src = fetchurl {
    url = "https://github.com/yvgude/lean-ctx/releases/download/v${version}/lean-ctx-aarch64-apple-darwin.tar.gz";
    sha256 = "b23133e86753a41864e2810751c67bf0583506528a53f48157edc4aacc5adb55";
  };

  dontBuild = true;
  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin lean-ctx
    chmod +x $out/bin/lean-ctx
    runHook postInstall
  '';

  # arm64 Mach-O carries a linker-signed (adhoc) signature; stripping or
  # rewriting it invalidates the signature and macOS refuses to exec the
  # binary. Nothing here needs fixup anyway.
  dontFixup = true;

  meta = with lib; {
    description = "Context gateway for AI agents: compress tool output to save tokens";
    longDescription = ''
      LeanCTX sits between an AI agent and its tools, compressing command, read
      and grep output plus shell history so less of the context window is spent
      on noise. It ships an MCP server, a shell hook and per-editor setup
      (`lean-ctx onboard`). The SKILL.md it installs into agent skill dirs is
      embedded in the binary itself, so no extra share directory is needed.
    '';
    homepage = "https://leanctx.com";
    changelog = "https://github.com/yvgude/lean-ctx/releases/tag/v${version}";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [binaryNativeCode];
    mainProgram = "lean-ctx";
    platforms = ["aarch64-darwin"];
  };
}
