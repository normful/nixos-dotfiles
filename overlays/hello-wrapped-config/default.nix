# Overlay: hello-wrapped-config
#
# Creates hello-wrapped — wraps the standard hello binary with extra CLI
# flags via makeWrapper. Demonstrates how to inject default flags, env
# vars, or PATH entries into an existing package without modifying its source.
#
# The key technique is using stdenv.mkDerivation with dontUnpack to create
# a thin derivation that wraps the binary.
#
# makeWrapper (from pkgs.buildPackages.makeWrapper) is the standard Nix
# utility for wrapping binaries with additional arguments or environment.
final: prev: {
  hello-wrapped = prev.stdenv.mkDerivation {
    name = "hello-wrapped-${prev.hello.version}";
    # Use the hello package as a "source" (bypass unpack/make)
    src = prev.hello;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${prev.hello}/bin/hello $out/bin/hello-wrapped \
        --add-flags "--greeting='Hello from a wrapped overlay!'"
    '';
    buildInputs = [ prev.makeWrapper ];
  };
}
