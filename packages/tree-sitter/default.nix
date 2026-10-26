{pkgs}: let
  version = "0.27.1";
  src = pkgs.fetchurl {
    url = "https://github.com/tree-sitter/tree-sitter/releases/download/v${version}/tree-sitter-macos-arm64.gz";
    hash = "sha256-RsuX2aLFLJTiLZp2wvERYVa4th+YNg4qnM4F/LGXzU0=";
  };
in
  pkgs.runCommand "tree-sitter-${version}"
  {
    nativeBuildInputs = [pkgs.gzip];
    meta = {
      description = "Parser generator tool and an incremental parsing library";
      homepage = "https://github.com/tree-sitter/tree-sitter";
      mainProgram = "tree-sitter";
      license = pkgs.lib.licenses.mit;
      platforms = ["aarch64-darwin"];
    };
  }
  ''
    mkdir -p $out/bin
    gunzip -c ${src} > $out/bin/tree-sitter
    chmod +x $out/bin/tree-sitter
  ''
