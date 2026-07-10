# Overlay: figlet-patched
#
# Patches figlet to change the default font from "standard" to "smslant".
# Demonstrates two idiomatic Nix patterns:
#
# 1. Patching source via overrideAttrs: injects a local patch into the
#    existing figlet derivation without forking the whole package.
# 2. Selective test fixture override: when a patch changes default output,
#    only the affected test expected-output files are replaced (via preCheck)
#    rather than disabling doCheck entirely — keeping the rest of upstream's
#    test coverage intact.
final: prev: {
  figlet-patched = prev.figlet.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./patches/default-font-smslant.patch ];
    # preCheck runs after unpack/patch but before the test target.
    # Here we copy local expected-output files into the build tree,
    # overriding only the fixtures that differ when smslant becomes default.
    preCheck = (old.preCheck or "") + ''
      cp ${./tests}/*.txt tests/
    '';
  });
}
