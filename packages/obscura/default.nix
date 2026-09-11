# obscura – built from source (cargo), no nixpkgs package exists
# https://github.com/h4ckf0r0day/obscura
#
# Pinned to the v0.2.2 release tag. Note that upstream never bumps Cargo.toml:
# it reads `version = "0.1.0"` on every commit, the release tag included. The
# release number exists only in the git tag, which obscura-cli/build.rs reads
# via GITHUB_REF_NAME at release time. So a source build of any rev reports
# 0.1.0 unless OBSCURA_VERSION is set — `version` + that env var below are what
# make `obscura --version` agree with the official release binary.
#
# Built with the `render,stealth` feature set, i.e. upstream's
#   cargo build --release -p obscura-cli --bins --features render,stealth
# `--bins` is deliberate: it covers both `obscura` and `obscura-worker`, which
# upstream requires to sit next to each other (the parallel `scrape` command
# spawns the worker as a sibling). Both binaries land in $out/bin.
#
# Two build-time downloads have to be neutralised for the sandbox:
#   * V8: deno_core's `v8` crate downloads a prebuilt librusty_v8 archive from
#     its own GitHub releases unless RUSTY_V8_ARCHIVE points at a local file,
#     so the matching archive is prefetched below. The archive version must
#     equal the `v8` crate version in Cargo.lock.
#   * BoringSSL (stealth → wreq → btls-sys): that crate carries the BoringSSL
#     sources and cmake-builds them, but its build script shells out to
#     `git init` + `git apply` to patch them first, hence cmake + git. No Go
#     is needed on darwin: the prefix-symbols path that wants it is only
#     enabled for linux/android targets, and BoringSSL's asm is pre-generated.
#
# To update to a newer release:
#   1. Set `version` to the new tag (e.g. "0.2.3"); `rev` follows it as
#      "v${version}".
#   2. Refresh `hash`: temporarily set it to `lib.fakeHash`, run
#        `nix build` on this package, and copy the `got: sha256-…`
#        value from the hash-mismatch error. (Do NOT use
#        `nix store prefetch-file` on the archive tarball — that hashes
#        the .tar.gz file, while fetchFromGitHub hashes the unpacked tree.)
#   3. Refresh the vendored lockfile from the same tag:
#        curl -sL https://raw.githubusercontent.com/h4ckf0r0day/obscura/v${version}/Cargo.lock \
#          -o packages/obscura/Cargo.lock
#   4. Read the `v8` version out of that lockfile; if it moved, bump
#      v8Version and both hashes below (`nix store prefetch-file --json`
#      on the matching librusty_v8_release_*.a.gz release asset).
#   5. `nix build` to verify.
{
  lib,
  fetchFromGitHub,
  fetchurl,
  rustPlatform,
  stdenv,
  cmake,
  git,
}:

let
  # Must match the `v8` crate version in Cargo.lock — rusty_v8 cuts one
  # prebuilt archive release per crate version, tagged v<version>.
  v8Version = "137.3.0";

  librusty_v8 = fetchurl {
    name = "librusty_v8_release-${v8Version}";
    url = "https://github.com/denoland/rusty_v8/releases/download/v${v8Version}/librusty_v8_release_${stdenv.hostPlatform.rust.rustcTarget}.a.gz";
    hash =
      {
        aarch64-darwin = "sha256-YFA9ZyTlUsRrAewmChXnnobEcVtxl8XGJ0iRG/H04HA=";
        x86_64-darwin = "sha256-ZnFsCn2VDqLHKqr2oMGkAqO6xV/fwLQ0H0mzjpr+zXU=";
      }
      .${stdenv.hostPlatform.system};
  };
in
rustPlatform.buildRustPackage rec {
  pname = "obscura";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "h4ckf0r0day";
    repo = "obscura";
    rev = "v${version}";
    hash = "sha256-ponNfeiRO4ajUYRZ3Pz3JYtPW1j8OP5jGDSF/a6PYuw=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  cargoBuildFlags = [
    "--package"
    "obscura-cli"
    "--bins"
  ];

  buildFeatures = [
    "render"
    "stealth"
  ];

  # The v8 crate would download its release archive itself; given a store path
  # it copies the archive instead (see download_file() in the crate's build.rs).
  env.RUSTY_V8_ARCHIVE = librusty_v8;

  # fetchFromGitHub strips .git, so obscura-cli/build.rs cannot ask git for a
  # tag and would fall back to the stale "0.1.0" in Cargo.toml. This is the
  # same string upstream's release workflow derives from the tag, i.e. exactly
  # what the official v0.2.2 binary reports.
  env.OBSCURA_VERSION = version;

  nativeBuildInputs = [
    cmake # btls-sys builds BoringSSL with cmake
    git # btls-sys runs `git init` + `git apply` on the vendored BoringSSL
    rustPlatform.bindgenHook # btls-sys generates its FFI bindings with bindgen
  ];

  # Upstream's test suites need network access and live services.
  doCheck = false;

  meta = with lib; {
    description = "Headless browser for AI agents and web scraping";
    longDescription = ''
      Obscura is a headless browser engine written in Rust. It runs real
      JavaScript through V8, speaks the Chrome DevTools Protocol, and works as
      a drop-in replacement for headless Chrome with Puppeteer and Playwright
      at a fraction of the memory. Built from source with the `render` and
      `stealth` features: native layout/paint (screenshots, screencast, PDF)
      and a Chrome-like TLS fingerprint.
    '';
    homepage = "https://github.com/h4ckf0r0day/obscura";
    license = licenses.asl20;
    mainProgram = "obscura";
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  };
}
