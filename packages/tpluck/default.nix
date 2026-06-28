{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "tpluck";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "tomis007";
    repo = "tpluck";
    rev = "66708e09eb39a619f33c8e613cc15d0b84fc9299";
    hash = "sha256-Gbve7tGYT0Cx2FF1nzmo/PGSpRek35Uit4p3s/JyHcs=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  doCheck = false;

  meta = with lib; {
    description = "Select text really fast — interactive terminal text picker with fuzzy search";
    longDescription = ''
      TPluck is a terminal UI tool that reads piped input, lets you search
      and select lines interactively using fuzzy matching, and outputs your
      selection to stdout. Written in Rust with crossterm.
    '';
    homepage = "https://github.com/tomis007/tpluck";
    license = licenses.mit;
    mainProgram = "tpluck";
    platforms = [ "aarch64-darwin" ];
  };
}
