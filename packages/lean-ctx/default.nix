{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "lean-ctx";
  version = "3.6.0";

  src = fetchFromGitHub {
    owner = "yvgude";
    repo = "lean-ctx";
    rev = "v${version}";
    hash = "sha256-jNL49MTpSIia/a5gEhWuIXFCzY5Q/sEryUbsbq497a0=";
  };

  sourceRoot = "${src.name}/rust";
  cargoHash = "sha256-2qiUkmt2+hWwzY6GdFl9jU5GfW2cGJ0UsbuitBcc7xg=";

  # Opt out of default features (which include jemalloc) — jemalloc is slow to compile
  buildNoDefaultFeatures = true;
  # Choose features explicitly — see full list at:
  # https://github.com/yvgude/lean-ctx/blob/3.6.0/rust/Cargo.toml#L51-L92
  buildFeatures = [
    "tree-sitter"
    "embeddings"
    "secure-update"
  ];

  doCheck = false;

  postInstall = ''
    mkdir -p $out/share/skills/lean-ctx
    cp -r $src/skills/lean-ctx/* $out/share/skills/lean-ctx/
    chmod -R +w $out/share/skills/lean-ctx
  '';

  doInstallCheck = true;

  meta = with lib; {
    homepage = "https://leanctx.com";
    changelog = "https://github.com/yvgude/lean-ctx/releases/tag/v${version}";
    sourceProvenance = with sourceTypes; [ fromSource ];
    mainProgram = "lean-ctx";
    platforms = [ "aarch64-darwin" ];
  };
}
