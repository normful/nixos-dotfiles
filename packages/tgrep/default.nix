# tgrep – prebuilt binaries, no nixpkgs package exists
# https://github.com/microsoft/tgrep
#
# Upstream releases one tarball per platform; each contains `./tgrep`
# plus `./README.md`. The binary is already named `tgrep`, so extract
# only it. Linux builds are static-pie musl (no interpreter), macOS
# links only system libs — no autoPatchelfHook needed.
{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "1.0.4";
  base = "https://github.com/microsoft/tgrep/releases/download/v${version}";

  sources = {
    aarch64-darwin = {
      url = "${base}/tgrep-v${version}-aarch64-apple-darwin.tar.gz";
      sha256 = "9ef13569d6725bb50497671506c914aaf6602fb0631810c8d100214498497ec8";
    };
    x86_64-darwin = {
      url = "${base}/tgrep-v${version}-x86_64-apple-darwin.tar.gz";
      sha256 = "10c73c378d92c93f81d12706bc02c413c7626c4ed8f178ac0d23abd461bbd643";
    };
    aarch64-linux = {
      url = "${base}/tgrep-v${version}-aarch64-unknown-linux-musl.tar.gz";
      sha256 = "8df6ab6ab6d859c38df3c6ee39c39bab66165761371a46a325021dd3c25607fb";
    };
    x86_64-linux = {
      url = "${base}/tgrep-v${version}-x86_64-unknown-linux-musl.tar.gz";
      sha256 = "81fd408f619fc1a316ed0618b2d2062b463631bdfd71123050580293817074fb";
    };
  };

  src = fetchurl sources.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation rec {
  pname = "tgrep";
  inherit version src;

  dontBuild = true;
  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin tgrep
    chmod +x $out/bin/tgrep
    runHook postInstall
  '';

  meta = with lib; {
    description = "Trigram-indexed grep with a client/server architecture for fast regex search in large codebases locally";
    homepage = "https://github.com/microsoft/tgrep";
    changelog = "https://github.com/microsoft/tgrep/releases/tag/v${version}";
    license = licenses.mit;
    mainProgram = "tgrep";
    platforms = builtins.attrNames sources;
  };
}
