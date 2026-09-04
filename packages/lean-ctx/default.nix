{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "lean-ctx";
  version = "3.9.20";

  src = fetchFromGitHub {
    owner = "yvgude";
    repo = "lean-ctx";
    rev = "v${version}";
    hash = "sha256-A1k7Mkl2doldHpLyAEWXjxUZBum6v+ngNu7c1YlMX2g=";
  };

  sourceRoot = "${src.name}/rust";
  cargoHash = "sha256-9IDNnGnj+DNXUe6IAkIO6bGddGCNblJq6BMsR83lOIg=";

  # Opt out of default features (which include jemalloc) — jemalloc is slow to compile
  buildNoDefaultFeatures = true;
  # Choose features explicitly — see full list at:
  # https://github.com/yvgude/lean-ctx/blob/3.9.20/rust/Cargo.toml#L52-L93
  buildFeatures = [
    "tree-sitter"
    "embeddings"
    "http-server"
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
