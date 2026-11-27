# browse – prebuilt binary from the Anomaly release service
# https://github.com/anomalyco/browse
#
# browse is the MCP relay that lets an AI agent drive the user's real
# Chrome-family browser through the browse extension.
#
# The upstream `curl -fsSL https://opencode.ai/browse/install | bash` path is
# deliberately not used. `browse install` classifies the running executable by
# location (rust/crates/browse/src/method.rs, `detect`); anything that is not
# `$XDG_BIN_HOME/browse` is `Install::Other`, and `place()` then copies the
# executable to ~/.local/bin and makes that copy the self-updating one — a
# second browse forked out of the store. The Nix install therefore ships the
# binary alone and the agent config is wired by hand (chezmoi source
# dot_pi/agent/mcp.json in the private source, entry: `<browse> mcp`).
#
# Updating: bump `version`, then take `sha256` from the channel manifest. The
# download URL is content-addressed by that same hash, so the two move
# together:
#   curl -s https://anoma.ly/release/browse/cli/stable.json \
#     | jq -r '.release.version, .release.targets["macos-arm64"]'
{
  lib,
  fetchurl,
  makeWrapper,
  stdenvNoCC,
}: let
  version = "0.1.5";

  # Upstream ships ten targets (macos/windows/linux × arm64/x64, plus
  # -baseline and -musl builds). Only the aarch64-darwin one is shipped here,
  # matching packages/opencode and packages/agent-browser: this flake has a
  # single host, cyan, and an asset that has never been built or run here is
  # not worth claiming.
  asset = "opencode-browse-darwin-arm64-${version}.tgz";
  sha256 = "d63b30d9b89d05070a3310d2d80435e06ab9cc35216b801acc68f969e14202bf";

  src = fetchurl {
    url = "https://anoma.ly/release/browse/files/${sha256}/${asset}";
    inherit sha256;
  };
in
  stdenvNoCC.mkDerivation {
    pname = "browse";
    inherit version src;

    nativeBuildInputs = [makeWrapper];

    dontBuild = true;
    dontConfigure = true;

    # The tarball holds package/bin/browse, package/LICENSE and
    # package/package.json; stdenv's unpacker wants a single top-level
    # directory and would keep the `package/` level anyway.
    dontUnpack = true;

    # The asset is a Rust binary signed ad-hoc by the linker
    # (flags=0x20002(adhoc,linker-signed), no TeamIdentifier). Strip rewrites
    # the Mach-O and invalidates that signature, after which macOS refuses to
    # exec it, so fixup is skipped entirely.
    dontFixup = true;

    # `browse update` would otherwise be the only thing in this package that
    # writes outside the store. mode default is `on` (update.rs, stored_mode),
    # and `OPENCODE_BROWSER_AUTO_UPDATE` overrides it for every process that
    # inherits this wrapper's environment, including the relay that
    # `browse mcp` starts (relay.rs `start_from` passes every
    # OPENCODE_BROWSER_* variable through its env_clear).
    #
    # Note this stops browse from installing or restarting onto a release, not
    # from reaching the network: the relay's updater thread checks the channel
    # manifest hourly for every install kind except a checkout build, before
    # it consults the mode. Nothing env-set can turn that check off.
    installPhase = ''
      runHook preInstall

      tar -xzf $src -C . --strip-components=2 package/bin/browse
      install -Dm755 browse $out/bin/browse

      wrapProgram $out/bin/browse \
        --set OPENCODE_BROWSER_AUTO_UPDATE off \
        --set OPENCODE_BROWSER_UPDATE_CHECK 0

      runHook postInstall
    '';

    meta = with lib; {
      description = "MCP relay that lets AI agents use your real browser";
      longDescription = ''
        browse runs a local relay that an agent reaches over MCP (stdio: `browse
        mcp`, which starts the relay on demand). Through the paired browse
        extension it drives the user's own Chrome-family browser — tabs, clicks,
        fills, screenshots, and JavaScript evaluated against the page — or a
        Firefox-family browser over WebDriver BiDi. Pairing is interactive and
        lives outside this package: `browse extension` then `browse pair`.
      '';
      homepage = "https://github.com/anomalyco/browse";
      changelog = "https://github.com/anomalyco/browse/commits/main";
      license = licenses.mit;
      mainProgram = "browse";
      platforms = ["aarch64-darwin"];
      sourceProvenance = with sourceTypes; [binaryNativeCode];
    };
  }
