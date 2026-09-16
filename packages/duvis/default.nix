# duvis – built from source (cargo), no nixpkgs package exists
# https://github.com/yamadashy/duvis
#
# NOTE: this deliberately uses the crates.io tarball (`fetchCrate`) rather
# than `fetchFromGitHub`. The git tree is missing `prebuilt/ui.html`
# (gitignored, regenerated via `just ui-build-prebuilt` before each
# publish), and its `build.rs` would otherwise try to `npm ci` + rebuild
# the React UI from `ui/` inside the sandbox, where network is disabled.
# The crates.io tarball ships the prebuilt UI, so `build.rs` just stages it
# for `include_str!` — no Node.js needed, same as `cargo install duvis`.
#
# To update to a newer version:
#   1. Set `version` to the new release.
#   2. Refresh the crate hash:
#        nix store prefetch-file \
#          https://static.crates.io/crates/duvis/duvis-<version>.crate
#      (`prefetch-file` is correct here — `fetchCrate` hashes the file,
#      unlike `fetchFromGitHub` which hashes the unpacked tree.)
#   3. Set `cargoHash` below to `lib.fakeHash`, run `nix build` on this
#      package, and copy the `got: sha256-…` value from the mismatch error.
#   4. `nix build` to verify, then smoke-test `<result>/bin/duvis`.
{
  lib,
  fetchCrate,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "duvis";
  version = "0.1.8";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-OD2KzH6iEPtOLyNh9yg3JugHYhG5sOEWDQafonTo/Fo=";
  };

  # No git deps in Cargo.lock, no -sys crates beyond libc — pure Rust,
  # so no outputHashes or extra native/system inputs needed.
  cargoHash = "sha256-bJHuOJGKrg7vvoY+l/UMhUFR64JnnUI40cnUPAy5fgg=";

  # Single binary (src/main.rs, no [[bin]] sections). Upstream test
  # suites need network and tempdir fixtures.
  doCheck = false;

  meta = with lib; {
    description = "Disk usage visualizer for both AI and humans";
    longDescription = ''
      duvis is a fast, read-only disk usage analyzer. Point it at any
      directory and get a structured JSON tree, a category summary, or a
      colorized terminal tree — or serve an interactive React + d3 browser
      UI with treemap, sunburst, and list views. Every entry is
      auto-tagged by category (cache, build, log, vcs, media, ide).
    '';
    homepage = "https://github.com/yamadashy/duvis";
    license = licenses.mit;
    mainProgram = "duvis";
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
  };
}
