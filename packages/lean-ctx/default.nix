{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "lean-ctx";
  version = "3.5.25";

  src = fetchFromGitHub {
    owner = "yvgude";
    repo = "lean-ctx";
    rev = "513ef79c57d2eade41d308eb71423c60414c00f5";
    hash = "sha256-3/YAmN4iO7cngj2DbXm9vAutxiz483qf7a81odxQOl8=";
  };

  sourceRoot = "${finalAttrs.src.name}/rust";

  cargoLock = {
    lockFile = "${finalAttrs.src}/rust/Cargo.lock";
  };

  # Upstream's test suite exercises shell/sandbox behavior and is not stable
  # under Nix builds, but the release binary itself builds fine.
  doCheck = false;

  meta = {
    homepage = "https://github.com/yvgude/lean-ctx";
    license = lib.licenses.mit;
    mainProgram = "lean-ctx";
    platforms = lib.platforms.linux;
  };
})
