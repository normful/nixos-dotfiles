{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:
let
  # origin/main commit of normful/zk (also tagged v0.15.0-fork.1).
  # Single source of truth: used for both fetching the source and stamping
  # the version. To bump, update this and `hash` below.
  # Re-fetch with: git ls-remote https://github.com/normful/zk.git refs/heads/main
  rev = "62230f5567b95944be0083cb43b66bd9f40b4499";
in
buildGoModule rec {
  pname = "zk-fork";
  version = "0.15.0-fork.1";

  src = fetchFromGitHub {
    owner = "normful";
    repo = "zk";
    inherit rev;
    hash = "sha256-RNyXPOVhDn95jSaBgZ8x7MzO30B8S8jW2iaYYl5TrSs=";
  };

  vendorHash = "sha256-Y5KI3o4HYWyqQl/RnOetyIKOI+CbYWSgrbkGkpAKsX4=";

  doCheck = false;

  env.CGO_ENABLED = 1;

  tags = [ "fts5" ];

  ldflags = [
    "-X=main.Version=${rev}-normful-fork"
  ];

  meta = with lib; {
    description = "Zettelkasten plain text note-taking assistant (normful fork)";
    longDescription = ''
      zk is a command-line tool for maintaining a plain text Zettelkasten or
      personal wiki. This package builds the normful fork from source
      (https://github.com/normful/zk), mirroring the upstream nixpkgs build:
      buildGoModule with CGO_ENABLED=1, fts5 tag for SQLite FTS5, and the
      version stamped via -X main.Version.
    '';
    homepage = "https://github.com/normful/zk";
    license = licenses.gpl3;
    mainProgram = "zk";
    platforms = [ "aarch64-darwin" ];
  };
}
