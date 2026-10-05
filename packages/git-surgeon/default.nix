# git-surgeon – prebuilt binaries, no nixpkgs package exists
# https://github.com/raine/git-surgeon
{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.1.17";
  base = "https://github.com/raine/git-surgeon/releases/download/v${version}";

  sources = {
    aarch64-darwin = {
      url = "${base}/git-surgeon-darwin-arm64.tar.gz";
      sha256 = "d8b6e08465ceb3aebc322d52da71afd93fe1b6628488e7059e08056e55b2b787";
    };
    x86_64-darwin = {
      url = "${base}/git-surgeon-darwin-amd64.tar.gz";
      sha256 = "c514e05a3638e8fe69d3577719be1553645905a1713263498b1c381ceed1b2b7";
    };
    aarch64-linux = {
      url = "${base}/git-surgeon-linux-arm64.tar.gz";
      sha256 = "c0f902befcdd05b140fcd05360daeaa5fde3aed7d492ef4131676676fe7ca908";
    };
    x86_64-linux = {
      url = "${base}/git-surgeon-linux-amd64.tar.gz";
      sha256 = "7bd03670ec02fd6e9e8c62e4cb69d9f85e3cb2d92976d8bc3077547bdf307db6";
    };
  };

  src = fetchurl sources.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "git-surgeon";
  inherit version src;

  dontBuild = true;
  dontConfigure = true;
  dontUnpack = true;

  # Archive contains a single statically linked binary named `git-surgeon`.
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin git-surgeon
    chmod +x $out/bin/git-surgeon
    runHook postInstall
  '';

  meta = with lib; {
    description = "Non-interactive hunk-level git staging, unstaging, discarding, undoing, fold, amend, squash, commit splitting, and commit reordering";
    homepage = "https://github.com/raine/git-surgeon";
    changelog = "https://github.com/raine/git-surgeon/releases/tag/v${version}";
    license = licenses.mit;
    mainProgram = "git-surgeon";
    platforms = builtins.attrNames sources;
  };
}
