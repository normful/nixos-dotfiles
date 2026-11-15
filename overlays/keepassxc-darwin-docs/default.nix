# Overlay: keepassxc-darwin-docs
#
# keepassxc 2.8.0 (nixpkgs-unstable-2611 pin 4fe25e12) declares a "doc" and
# "man" output on every platform and unconditionally moves the rendered docs
# out of $out during postInstall:
#
#   mkdir -p $doc/share/doc
#   mv $out/share/keepassxc/docs/ $doc/share/doc/keepassxc
#
# On Darwin CMake installs everything into the .app bundle, so the docs land in
# $out/Applications/KeePassXC.app/Contents/Resources/docs, the `mv` fails with
# "cannot stat '.../share/keepassxc/docs/'", and darwin-rebuild aborts.
#
# Upstream nixpkgs fixed this on master by only declaring and populating the
# doc/man outputs when `withKeePassDocs && stdenv.hostPlatform.isLinux`. This
# overlay applies the same shape to the pinned revision, which makes the docs
# stay inside the bundle. Once the pin contains the fix the replaceStrings no
# longer matches and the overlay is a no-op.
final: prev: {
  keepassxc =
    if !prev.stdenv.hostPlatform.isDarwin
    then prev.keepassxc
    else
      prev.keepassxc.overrideAttrs (old: {
        # An empty output directory still has to be produced, so dropping the
        # two outputs is required — not just the mv.
        outputs = ["out"];
        postInstall =
          prev.lib.replaceStrings
          [
            (prev.lib.concatStringsSep "\n" [
              "mkdir -p $doc/share/doc"
              "mv $out/share/keepassxc/docs/ $doc/share/doc/keepassxc"
            ])
          ]
          [""]
          (old.postInstall or "");
      });
}
