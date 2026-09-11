---
name: add-nix-package-from-cargo-build
description: Add a new Nix package under packages/ that builds a Rust binary from source with rustPlatform.buildRustPackage, including Cargo.lock vendoring, git-dependency outputHashes, system-dependency mapping, and wiring into mac/cyan/configuration.nix
---

# Add Nix Package from Cargo Build

## Overview

**Package a Rust CLI tool by compiling it from source** (for repos/forks that publish no usable prebuilt binaries, or where a source build is preferred). Pattern: `fetchFromGitHub` the source, vendor `Cargo.lock` next to `default.nix`, resolve fixed-output hashes via deliberate build failures, map system dependencies, and ship only the wanted binary.

Reference examples in `packages/`:
- `jcode` — full pattern: fork source, vendored `Cargo.lock`, two git-dep `outputHashes`, system OpenSSL, `cmake`/`perl`/`pkg-config`, Darwin frameworks, `--bin` selection, build-time version-identity env vars
- `maki` — `outputHashes` for git deps, `cargoBuildFlags --package`, `postPatch` fix for a vendored crate
- `arxiv-cli` — pinned (untagged) commit, `outputHashes`, `perl` for vendored OpenSSL
- `git-ai` — `OPENSSL_NO_VENDOR`, `openssl` + `sqlite` in `buildInputs`, Darwin `libiconv` + `apple-sdk_15`
- `disky` — minimal template: `fetchFromGitHub` + vendored `Cargo.lock`, no extra inputs

## When to Use

- Rust tool with no nixpkgs package and no usable prebuilt release assets (e.g. a personal fork)
- A source build is wanted for patching, pinning, or transparency
- Follow this skill instead of inventing a new structure

## Process

```
┌─────────────────┐
│ 1. Probe repo:   │
│    bins, git     │
│    deps, sys     │
│    deps, version │
│    stamping      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 2. Vendor        │
│    Cargo.lock    │
│    next to       │
│    default.nix   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 3. Write         │
│    default.nix   │
│    with fakeHash │
│    placeholders  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 4. Build to      │
│    resolve real  │
│    hashes; fix;  │
│    rebuild       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 5. Wire into     │
│    mac/cyan/     │
│    configuration │
│    .nix; verify  │
│    binary runs   │
└─────────────────┘
```

## Quick Reference

| Step | Command | Purpose |
|------|---------|---------|
| Pin commit | `git ls-remote https://github.com/<owner>/<repo>.git HEAD` | `rev` for `fetchFromGitHub` |
| Download lockfile | `curl -sL https://raw.githubusercontent.com/<owner>/<repo>/<rev>/Cargo.lock -o /tmp/<name>-Cargo.lock` | Inspect before vendoring |
| Git deps | `grep -A3 'source = "git' /tmp/<name>-Cargo.lock` | Each needs an `outputHashes` entry keyed `<crate>-<version>` |
| `-sys` crates | `grep '^name = ".*-sys"' /tmp/<name>-Cargo.lock \| sort -u` | Map to system inputs (see table below) |
| Bin targets | `curl -sL https://raw.githubusercontent.com/<owner>/<repo>/<rev>/Cargo.toml` → `[[bin]]` sections | Decide `cargoBuildFlags --bin/--package` |
| License + blurb | `curl -s https://api.github.com/repos/<owner>/<repo> \| jq -r '.description, .license.spdx_id'` | `meta.license`, `meta.description` |
| Resolve hashes | `nix build` with `lib.fakeHash` placeholders | Copy `got: sha256-…` values from mismatch errors |
| Format check | `nixfmt --check packages/<name>/default.nix` | Repo formatter is `nixfmt` (see `flake.nix`) |

### `-sys` crate → Nix input mapping

| Lockfile crate | Meaning | Nix inputs |
|----------------|---------|------------|
| `openssl-sys` **with** `openssl-src` in its deps | Vendored OpenSSL (feature `vendored` on) | `perl` in `nativeBuildInputs` |
| `openssl-sys` **without** `openssl-src` | Links system OpenSSL | `pkg-config` native; `openssl` in `buildInputs` (or set `OPENSSL_NO_VENDOR = "1"` explicitly, see `git-ai`) |
| `libsqlite3-sys` with `rusqlite` `features = ["bundled"]` (check dependent crate's `Cargo.toml`) | SQLite compiled from source | C compiler from stdenv is enough; no input needed |
| `aws-lc-sys` | Rustls TLS C++ build | `cmake` in `nativeBuildInputs` (+ `perl` to be safe) |
| `oniguruma-sys` (via `tokenizers` `onig`), `libz-sys`, etc. | Bundled C sources | Usually nothing extra beyond stdenv |
| `objc2-*`, `global-hotkey` on macOS | Apple frameworks | `libiconv` + `apple-sdk_15` under `lib.optionals stdenv.hostPlatform.isDarwin` (see `git-ai`) |

## Implementation

### Step 1: Probe the repo

1. Read the root `Cargo.toml`: note `[package] version`, every `[[bin]]` name, `[features]` defaults (are heavy features like `embeddings`/`bedrock` on by default? — the Nix build compiles default features unless `cargoBuildFlags` says otherwise), and any `[target.'cfg(target_os = "macos")'.dependencies]`.
2. From `Cargo.lock`: list `source = "git…"` deps (name + version for `outputHashes` keys) and `-sys` crates (map via the table above).
3. Check for a build-time version-stamping script (`build.rs`, `crates/*build-meta*`). If it shells out to `git`, the Nix build (which strips `.git`) will emit `unknown` — look for documented env-var overrides (e.g. `JCODE_BUILD_GIT_HASH` / `JCODE_BUILD_GIT_DATE`) and set them from the pinned commit.
4. Check `.gitmodules` — submodules are **not** fetched by `fetchFromGitHub` unless `fetchSubmodules = true`; prefer avoiding repos that need them.

### Step 2: Vendor `Cargo.lock`

```bash
curl -sL https://raw.githubusercontent.com/<owner>/<repo>/<rev>/Cargo.lock \
  -o packages/<name>/Cargo.lock
```

This file is committed to the repo and referenced as `cargoLock.lockFile = ./Cargo.lock`. It must be refreshed on every `rev` bump. (Alternative `cargoHash` style exists — see `lean-ctx` — but the vendored-lockfile style is the repo convention.)

### Step 3: Create `packages/<name>/default.nix`

Template (copy `packages/jcode/default.nix` and adapt):

```nix
# <name> – built from source (cargo), no nixpkgs package exists
# https://github.com/<owner>/<repo>
#
# To update to a newer commit:
#   1. Set `rev` to the new HEAD.
#   2. Refresh `hash`: temporarily set it to `lib.fakeHash`, run
#        `nix build` on this package, and copy the `got: sha256-…`
#        value from the hash-mismatch error. (Do NOT use
#        `nix store prefetch-file` on the archive tarball — that hashes
#        the .tar.gz file, while fetchFromGitHub hashes the unpacked tree.)
#   3. Refresh the vendored lockfile from the same commit:
#        curl -sL https://raw.githubusercontent.com/<owner>/<repo>/<rev>/Cargo.lock \
#          -o packages/<name>/Cargo.lock
#   4. `nix build` to verify (updates outputHashes below if git deps changed).
{
  lib,
  fetchFromGitHub,
  rustPlatform,
  stdenv,
  # Add per Step 1 mapping: cmake, perl, pkg-config,
  # openssl, libiconv, apple-sdk_15, …
}:

rustPlatform.buildRustPackage rec {
  pname = "<name>";
  version = "<Cargo.toml [package] version at the pinned rev>";

  src = fetchFromGitHub {
    owner = "<owner>";
    repo = "<repo>";
    rev = "<full 40-char HEAD sha>";
    hash = lib.fakeHash; # resolve via Step 4 on first creation
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      # One entry per `source = "git…"` dep in Cargo.lock.
      # Key format: "<crate-name>-<crate-version>".
      "<git-crate>-<version>" = lib.fakeHash; # resolve via Step 4
    };
  };

  # Ship only the wanted binary when the workspace defines extras
  # (dev tools, benches, harness bins). Omit entirely for single-bin crates.
  cargoBuildFlags = [
    "--bin"
    "<name>"
  ];

  nativeBuildInputs = [
    # e.g. cmake, perl, pkg-config
  ];

  buildInputs = [
    # e.g. openssl
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    libiconv
    apple-sdk_15
  ];

  # Upstream test suites usually need network, ptys, or live services.
  doCheck = false;

  meta = with lib; {
    description = "<short description>";
    longDescription = ''
      <Two to three sentences: what it is, what it does.>
    '';
    homepage = "https://github.com/<owner>/<repo>";
    license = licenses.<spdx>;
    mainProgram = "<installed binary name>";
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
  };
}
```

Adaptations:
- **Single-bin crate, no git deps, no sys deps**: drop `cargoBuildFlags`, `outputHashes`, and extra inputs (see `disky`).
- **Crate needs a vendored-crate patch** (e.g. a relative-path `include_str!` that breaks under Nix vendoring): add `postPatch` with `substituteInPlace` on `$cargoDepsCopy` (see `maki`).
- **Multiple bins to ship**: repeat `--bin` pairs in `cargoBuildFlags`, or use `--package <pkg>` to build one workspace member's bins.
- **Build script needs commit identity**: set the repo's documented env vars (e.g. `JCODE_BUILD_GIT_HASH = "<short sha>";`) as top-level derivation attrs so `build.rs` emits real values instead of `unknown`.

### Step 4: Resolve hashes via build failures, then rebuild

1. Run `nix build` on the package (evaluate it standalone against the same nixpkgs the darwin config uses, e.g. via `callPackage` on `nixpkgs-2605` for `aarch64-darwin`).
2. First failure gives the real `src` hash (`got: sha256-…`); second round gives each `outputHashes` value. Fill them in one round at a time.
3. The real compile of a large workspace takes 10–60 minutes. Run it detached with output to a log file and poll (`nix build … > /tmp/<name>-build.log 2>&1; echo "EXIT:$?" > done-file`) rather than holding a foreground shell.
4. On success, confirm the installed binary set (`ls <result>/bin/`) and smoke-test it (`<result>/bin/<name> --version`, `--help`).

### Step 5: Wire into `mac/cyan/configuration.nix` and verify

Add beside similar tools, with a 2-line comment in file style:

```nix
      # <What it is>. <One-line why it matters>.
      # <Second line of context if needed>.
      (callPackage ../../packages/<name> { })
```

Then:

```bash
nixfmt --check packages/<name>/default.nix
```

Do not run `darwin-rebuild switch` — the user applies it.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using `nix store prefetch-file` output as `fetchFromGitHub.hash` | That hashes the `.tar.gz` file; `fetchFromGitHub` hashes the unpacked NAR tree. Always resolve via the `got:` line of the mismatch error |
| Guessing `outputHashes` or omitting a git dep | Every `source = "git…"` package in `Cargo.lock` needs a `<name>-<version>` entry; the vendor derivation fails naming the missing one |
| Forgetting `cmake`/`perl` for `aws-lc-sys` / vendored OpenSSL | C++ build-script failures mid-compile; map via the `-sys` table in Step 1 |
| Shipping dev/harness/bench bins | Set `cargoBuildFlags --bin <name>`; check `<result>/bin/` after building |
| Leaving version as `unknown` when the repo supports env overrides | Set the documented `*_BUILD_GIT_*` vars from the pinned commit; leave release-tag vars unset for fork snapshots |
| Running the full build in a foreground shell | It exceeds interactive timeouts; detach to a log file and poll |
| Editing `flake.lock` to fix a Rust build problem | Never — Rust vendoring is fully described by `Cargo.lock` + `outputHashes`; `flake.lock` is unrelated |
| Forgetting `mainProgram` / `platforms` in `meta` | Copy the `meta` block from the template verbatim and fill in |
