{
  lib,
  fetchFromGitHub,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "firstmate";
  version = "0-unstable-2026-06-29";

  src = fetchFromGitHub {
    owner = "kunchenguid";
    repo = "firstmate";
    rev = "1fb42263642700eeb5db0efe2b62f791981dc33a";
    hash = "sha256-8F/WiZxTdzRVTzm5f9JL0ATOlCyFwC5UnDg2K9rsk/w=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    # Install the full firstmate tree
    mkdir -p $out/share/firstmate
    cp -r . "$out/share/firstmate/"
    rm -rf "$out/share/firstmate/.git"

    # Helper commands on PATH for fm-bootstrap, fm-update, etc.
    # Note: most fm-* scripts source each other by relative path and expect
    # to run from within the firstmate tree. Set FM_ROOT_OVERRIDE so they
    # can find the Nix store tree even when invoked from a symlinked copy.
    mkdir -p $out/bin
    for f in "$out/share/firstmate/bin/"*.sh; do
      name=$(basename "$f")
      cat > "$out/bin/$name" << WRAPPER
#!/usr/bin/env bash
export FM_ROOT_OVERRIDE="$out/share/firstmate"
exec "$out/share/firstmate/bin/$name" "\$@"
WRAPPER
      chmod +x "$out/bin/$name"
    done

    # firstmate command: skeleton init, path, and help
    # Use @placeholder@ + substituteInPlace to avoid Nix interpolation
    # colliding with bash parameter expansion in heredocs.
    cat > "$out/bin/firstmate" << 'SCRIPT'
#!/usr/bin/env bash
FM="$HOME/.local/share/firstmate"
FM_STORE="@out@/share/firstmate"

case "'${1:-}" in
  init|bootstrap)
    if [ -f "$FM/.installed-version" ]; then
      echo "firstmate already initialized at $FM"
      echo "  cd $FM && <claude|codex|opencode|pi>"
      exit 0
    fi
    echo "Copying firstmate skeleton to $FM ..."
    mkdir -p "$FM"
    cp -r "$FM_STORE/"* "$FM/"
    rm -rf "$FM/.git" 2>/dev/null || true
    echo "@out@" > "$FM/.installed-version"
    echo ""
    echo "Ready, captain!"
    echo "  cd $FM && claude"
    ;;
  path)
    echo "$FM_STORE"
    ;;
  *)
    echo "firstmate — Talk to one agent. Ship with a crew."
    echo ""
    echo "  firstmate init       copy skeleton to ~/.local/share/firstmate/"
    echo "  firstmate path       print the Nix store path"
    echo "  cd ~/.local/share/firstmate && claude"
    echo ""
    echo "Helper scripts (fm-*) are on PATH for advanced use."
    ;;
esac
SCRIPT
    substituteInPlace "$out/bin/firstmate" --subst-var out
    chmod +x "$out/bin/firstmate"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Talk to one agent. Ship with a crew.";
    longDescription = ''
      firstmate is a directory-based framework that turns any terminal coding
      agent (Claude, Codex, Opencode, Pi) into a crew commander. You talk to
      a single agent — the first mate — and it spawns autonomous crewmates in
      tmux windows with clean git worktrees, supervises them, and hands you
      finished PRs or investigation reports.

      Quick start:
        firstmate init
        cd ~/.local/share/firstmate && claude

      Then just talk: "ahoy, fix the flaky login test and add dark mode"
    '';
    homepage = "https://github.com/kunchenguid/firstmate";
    license = licenses.mit;
    platforms = [ "aarch64-darwin" ];
  };
}
