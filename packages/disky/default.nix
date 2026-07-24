{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "disky";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "biliboss";
    repo = "disky";
    rev = "v${version}";
    hash = "sha256-iG8YH25mLikV+C/PAAQDyMkakpSLadq2JqLjtJ1gHJc=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  doCheck = false;

  meta = with lib; {
    description = "Fast macOS disk analyzer and cleanup CLI — ncdu/dust/GrandPerspective alternative";
    longDescription = ''
      disky is a fast macOS disk analyzer and cleanup CLI built in Rust.
      Scan 2M files in seconds, Trash-restorable cleanup, agent-native JSON.
      Features DuckDB-backed snapshots, diff between scans, TUI explorer
      (ratatui), cleanup wizard, APFS sparse-file awareness.
    '';
    homepage = "https://github.com/biliboss/disky";
    license = licenses.mit;
    mainProgram = "disky";
    platforms = [ "aarch64-darwin" ];
  };
}
