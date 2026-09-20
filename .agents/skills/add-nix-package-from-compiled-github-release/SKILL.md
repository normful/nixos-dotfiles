---
name: add-nix-package-from-compiled-github-release
description: Add a new Nix package under packages/ that installs a prebuilt binary from GitHub Releases, with multi-platform sources, hashes, and wiring into mac/cyan/configuration.nix
---

# Add Nix Package from Compiled GitHub Release

## Overview

**Package a CLI tool that publishes prebuilt binaries as GitHub Release assets** (common for Rust/Go tools with no nixpkgs package). Pattern: `fetchurl` the release tarball, disable build phases, extract and install the binary to `$out/bin`.

Reference examples in `packages/`:
- `dcg` — full pattern: multi-platform `sources` keyed by `stdenv.hostPlatform.system`
- `carbonyl` — zip asset with post-unpack quirks (dylib fixup, `makeWrapper` entry point)
- `tree-sitter` — single compressed binary (`.gz`), no tarball: `gunzip` straight into `$out/bin`
- `openfang`, `humanify` — minimal single-platform (`aarch64-darwin`) template

## When to Use

- New tool with assets under `github.com/<owner>/<repo>/releases/download/...`
- Building from source is not desired (or no nixpkgs package exists)
- Follow this skill instead of inventing a new structure

## Process

```
┌─────────────────┐
│ 1. Probe release │
│    tag, assets,  │
│    hashes, inner │
│    file layout   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 2. Create        │
│    packages/     │
│    <name>/       │
│    default.nix   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 3. Wire into     │
│    mac/cyan/     │
│    configuration │
│    .nix          │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 4. Parse-check;  │
│    build verifies│
│    hashes        │
└─────────────────┘
```

## Quick Reference

| Step | Command | Purpose |
|------|---------|---------|
| Latest tag + assets | `curl -s https://api.github.com/repos/<owner>/<repo>/releases/latest \| jq -r '.tag_name, (.assets[]?.name)'` | Pin version; see which platforms upstream ships |
| Download URL | `jq -r '.assets[] \| select(.name\|contains("<asset>")) \| .browser_download_url'` on same API output | Confirm `releases/download/v<ver>/<asset>` shape |
| Hashes | `curl -sL https://github.com/<owner>/<repo>/releases/download/<tag>/SHA256SUMS` (or per-asset `.sha256`) | `sha256` values; repo convention is bare hex |
| Inner layout | `curl -sL <tarball-url> -o /tmp/<name>.tgz; tar tzf /tmp/<name>.tgz` | Inner filenames; wrapper scripts; multi-file tarballs |
| File types | extract, then `/usr/bin/file <files>` | Mach-O vs ELF (dynamic → needs patchelf), scripts |
| Wrapper scripts | `cat` any small (≤1 KB) text file in the tarball | Check for hardcoded sibling names / env setup |
| License + blurb | `curl -s https://api.github.com/repos/<owner>/<repo> \| jq -r '.description, .license.spdx_id'` | `meta.license`, `meta.description` |
| Parse-check | `nix-instantiate --parse packages/<name>/default.nix` | Syntax only; real verification is the build |

## Implementation

### Step 1: Probe the release

Get the latest tag, asset list, hashes, and — critically — the **inner filenames** (they often differ from the installed binary name, e.g. `carbonyl`'s zip wraps everything in a `carbonyl-<platform>/` directory). Watch for:

- **Wrapper + binary pairs** (e.g. `carbonyl`: the `$out/bin` entry point is a `makeWrapper` shim over files kept at their upstream layout under `$out/libexec/carbonyl/` — don't flatten or rename what the wrapper expects)
- **Dynamically linked Linux ELF** (`interpreter /lib64/ld-linux…`) → needs `autoPatchelfHook`
- **Only Nix platforms matter**: `aarch64-darwin`, `x86_64-darwin`, `aarch64-linux`, `x86_64-linux`. Ignore `freebsd`/`windows` assets — `stdenv.hostPlatform.system` can never select them

### Step 2: Create `packages/<name>/default.nix`

Multi-platform template (copy `packages/dcg/default.nix` and adapt):

```nix
# <name> – prebuilt binaries, no nixpkgs package exists
# https://github.com/<owner>/<repo>
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

let
  version = "<tag without v, e.g. 0.84.0>";
  base = "https://github.com/<owner>/<repo>/releases/download/v${version}";

  sources = {
    aarch64-darwin = {
      url = "${base}/<asset-macos-aarch64>.tar.gz";
      sha256 = "<hex from SHA256SUMS>";
    };
    x86_64-darwin = {
      url = "${base}/<asset-macos-x86_64>.tar.gz";
      sha256 = "<hex from SHA256SUMS>";
    };
    aarch64-linux = {
      url = "${base}/<asset-linux-aarch64>.tar.gz";
      sha256 = "<hex from SHA256SUMS>";
    };
    x86_64-linux = {
      url = "${base}/<asset-linux-x86_64>.tar.gz";
      sha256 = "<hex from SHA256SUMS>";
    };
  };

  src = fetchurl sources.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation rec {
  pname = "<name>";
  inherit version src;

  dontBuild = true;
  dontConfigure = true;
  dontUnpack = true;

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin
    # Normalize the entry point; keep any `.bin` sibling under its
    # upstream name if a wrapper script references it by exact name.
    for f in $out/bin/<prefix>-*; do
      case "$f" in
        *.bin) ;;
        *) mv "$f" $out/bin/<name> ;;
      esac
    done
    chmod +x $out/bin/<name>
    runHook postInstall
  '';

  meta = with lib; {
    description = "<short description>";
    homepage = "https://github.com/<owner>/<repo>";
    changelog = "https://github.com/<owner>/<repo>/releases/tag/v${version}";
    license = licenses.<spdx>;
    mainProgram = "<name>";
    platforms = builtins.attrNames sources;
  };
}
```

Adaptations:
- **Single-platform** (darwin-only host, asset only for `aarch64-darwin`): drop the `sources` attrset; use `stdenvNoCC.mkDerivation` with inline `src = fetchurl { url = …; sha256 = …; };`, plain `mv` of the known inner name, and `platforms = [ "aarch64-darwin" ]` (see `openfang`). Omit `autoPatchelfHook`.
- **Single-file asset** (no tarball, e.g. `tree-sitter`'s `.gz`): skip `tar`, stream the file straight into `$out/bin/<name>` (`gunzip -c ${src} > $out/bin/<name>`).
- **Upstream lacks Linux/macOS-x86 assets**: include only the platforms that exist; `platforms` follows `sources` automatically.

### Step 3: Wire into `mac/cyan/configuration.nix`

Add beside similar tools (agent CLIs cluster near `swival`/`jcode`; pick the section that fits), with a 2-line comment in file style:

```nix
      # <What it is>. <One-line why it matters>.
      # <Second line of context if needed>.
      (callPackage ../../packages/<name> { })
```

### Step 4: Verify

```bash
nix-instantiate --parse packages/<name>/default.nix
```

This checks syntax only. The build itself verifies hashes (mismatch fails loudly). Do not run `darwin-rebuild switch` — the user applies it.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Setting `dontUnpack` but relying on auto-unpack (`sourceRoot`, `./binary` paths) | With `dontUnpack = true`, manually `tar -xzf $src` in `installPhase` |
| Assuming inner filename equals installed name | Always `tar tzf` first; `mv` inner → `$out/bin/<name>` |
| Renaming a `.bin` that a wrapper script references by exact name | Keep the sibling's upstream name; rename only the entry point |
| Missing `autoPatchelfHook` for dynamic Linux ELF | Add `lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ]` (macOS-only packages don't need it) |
| Converting hex hashes to SRI | Unnecessary — `fetchurl`'s `sha256` accepts the bare hex from `SHA256SUMS`, per repo convention |
| Adding `freebsd`/`windows` to `sources` | Never selectable via `stdenv.hostPlatform.system`; omit |
| Forgetting `mainProgram` / `platforms` in `meta` | Copy the `meta` block from the template verbatim and fill in |
