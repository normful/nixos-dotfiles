# jcode – prebuilt binaries, no nixpkgs package exists
# https://github.com/1jehuang/jcode
#
# Upstream releases one tarball per platform; each contains a single
# executable named after the asset, except linux-x86_64 which ships a
# wrapper script + `.bin` pair (the wrapper execs its `.bin` sibling
# by name and sets LD_LIBRARY_PATH to its own dir).
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

let
  version = "0.84.0";
  base = "https://github.com/1jehuang/jcode/releases/download/v${version}";

  sources = {
    aarch64-darwin = {
      url = "${base}/jcode-macos-aarch64.tar.gz";
      sha256 = "4661f312185575b88ab500ad9c3a97861062d493fb817aa4d721b057c7130401";
    };
    x86_64-darwin = {
      url = "${base}/jcode-macos-x86_64.tar.gz";
      sha256 = "3033c5ad0a50ae193650219eec3255b4f519c4cfbcd51521c76e599518a8ec45";
    };
    aarch64-linux = {
      url = "${base}/jcode-linux-aarch64.tar.gz";
      sha256 = "3852a93ab86a6a2098fb45fc631de3b2fb8304c3a04044b7669becfe9146f539";
    };
    x86_64-linux = {
      url = "${base}/jcode-linux-x86_64.tar.gz";
      sha256 = "e00eaede1a4f26812e77382bda9d82e2d301affd983d18ada38fddd43dce9571";
    };
  };

  src = fetchurl sources.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation rec {
  pname = "jcode";
  inherit version src;

  dontBuild = true;
  dontConfigure = true;
  dontUnpack = true;

  # Linux binaries are dynamically linked (ELF, /lib64/ld-linux …);
  # rewrite interpreter/RPATH for the Nix store (same as lightpanda).
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin
    # Normalize the entry point to `jcode`. The linux-x86_64 `.bin`
    # keeps its upstream name: its wrapper script execs the sibling
    # `jcode-linux-x86_64.bin` by exact name.
    for f in $out/bin/jcode-*; do
      case "$f" in
        *.bin) ;;
        *) mv "$f" $out/bin/jcode ;;
      esac
    done
    chmod +x $out/bin/jcode
    runHook postInstall
  '';

  meta = with lib; {
    description = "RAM-efficient terminal coding agent harness";
    longDescription = ''
      Jcode is a terminal coding agent harness built in Rust. Local terminal
      UI with remote execution over native SSH sessions, keeping the
      workspace, tools, and agent execution on the remote host.
    '';
    homepage = "https://github.com/1jehuang/jcode";
    changelog = "https://github.com/1jehuang/jcode/releases/tag/v${version}";
    license = licenses.mit;
    mainProgram = "jcode";
    platforms = builtins.attrNames sources;
  };
}
