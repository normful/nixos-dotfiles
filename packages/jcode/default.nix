# jcode – built from source (cargo), no nixpkgs package exists
# https://github.com/normful/jcode (fork of https://github.com/1jehuang/jcode)
#
# The fork publishes no compiled release tarballs, so this builds the
# `jcode` binary from source with rustPlatform.buildRustPackage.
#
# To update to a newer fork commit:
#   1. Set `rev` to the new master HEAD.
#   2. Refresh `hash`: temporarily set it to `lib.fakeHash`, run
#        `nix build` on this package, and copy the `got: sha256-…`
#        value from the hash-mismatch error. (Do NOT use
#        `nix store prefetch-file` on the release tarball — that hashes
#        the .tar.gz file, while fetchFromGitHub hashes the unpacked tree.)
#   3. Refresh the vendored lockfile from the same commit:
#        curl -sL https://raw.githubusercontent.com/normful/jcode/<rev>/Cargo.lock \
#          -o packages/jcode/Cargo.lock
#   4. `nix build` to verify (updates outputHashes below if git deps changed).
{
  lib,
  fetchFromGitHub,
  rustPlatform,
  cmake,
  perl,
  pkg-config,
  openssl,
  stdenv,
  libiconv,
  apple-sdk_15,
}:

rustPlatform.buildRustPackage rec {
  pname = "jcode";
  # Matches the fork's Cargo.toml [package] version at the pinned rev.
  version = "0.84.0";

  src = fetchFromGitHub {
    owner = "normful";
    repo = "jcode";
    rev = "879bf1ecd301bb7f87d215b638e15ef5b5aca57a";
    hash = "sha256-m3oBFOXGdaE+VKp1eahKbhBkFalUykkJhQPgMWCaAZU=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "agentgrep-0.1.6" = "sha256-yBLs2YZ6cUlTHYZGLtlAXpK7/9xX2kPi46B1YLbuPUU=";
      "mermaid-rs-renderer-0.3.1" = "sha256-uekh1vJ19dAPP7+4PiqSlJizApZLpDhBWBoyN+fgS9s=";
    };
  };

  # Only the main binary. The workspace also defines test_api,
  # jcode-harness, and feature-gated dev bench bins we don't ship.
  cargoBuildFlags = [
    "--bin"
    "jcode"
  ];

  # fetchFromGitHub strips .git, so the jcode-build-meta script can't
  # run git itself. Pass the pinned commit's identity explicitly so
  # `jcode --version` and the self-update ancestry check see the real
  # commit instead of "unknown" (same values a local `cargo build`
  # in the fork would emit). TAG is intentionally unset: this is a
  # fork snapshot, not an official release tag.
  JCODE_BUILD_GIT_HASH = "879bf1e";
  JCODE_BUILD_GIT_DATE = "2026-09-08 17:58:50 +0000";

  # cmake: aws-lc-sys (rustls TLS). perl: aws-lc/openssl-src build scripts.
  # pkg-config + openssl: imap/native-tls links system OpenSSL
  # (vendored OpenSSL is only behind the off-by-default
  # linux-compat-vendored-openssl feature). rusqlite uses its bundled
  # sqlite, so no system sqlite needed.
  nativeBuildInputs = [
    cmake
    perl
    pkg-config
  ];

  buildInputs = [
    openssl
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    libiconv
    apple-sdk_15
  ];

  doCheck = false;

  meta = with lib; {
    description = "RAM-efficient terminal coding agent harness";
    longDescription = ''
      Jcode is a terminal coding agent harness built in Rust. Local terminal
      UI with remote execution over native SSH sessions, keeping the
      workspace, tools, and agent execution on the remote host.
      Built from source from the normful/jcode fork.
    '';
    homepage = "https://github.com/normful/jcode";
    license = licenses.mit;
    mainProgram = "jcode";
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
  };
}
