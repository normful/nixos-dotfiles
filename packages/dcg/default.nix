# destructive_command_guard (dcg) – prebuilt binary, no nixpkgs package exists
# https://github.com/Dicklesworthstone/destructive_command_guard
#
# Adapted from https://github.com/bgyss/nixos-config (overlays/91-dcg.nix)
# as a standalone callPackage package instead of an overlay.
{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.9.2";
  base = "https://github.com/Dicklesworthstone/destructive_command_guard/releases/download/v${version}";

  sources = {
    aarch64-darwin = {
      url = "${base}/dcg-aarch64-apple-darwin.tar.xz";
      sha256 = "sha256-0TbHT4IWoaM/XgqcolKO3lmQVUr5Eprg8NoV4L6ZHrg=";
    };
    x86_64-darwin = {
      url = "${base}/dcg-x86_64-apple-darwin.tar.xz";
      sha256 = "sha256-rFJvHTjOI7AECIr3BfUt4r2/vfwWxqqOJUioqGmFyhw=";
    };
  };

  src = fetchurl sources.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "dcg";
  inherit version;
  inherit src;

  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 dcg $out/bin/dcg
    runHook postInstall
  '';

  meta = with lib; {
    description = "Destructive Command Guard - multi-agent safety hook that blocks destructive shell commands";
    homepage = "https://github.com/Dicklesworthstone/destructive_command_guard";
    license = licenses.mit;
    platforms = builtins.attrNames sources;
    mainProgram = "dcg";
  };
}
