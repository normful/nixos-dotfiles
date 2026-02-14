{
  lib,
  stdenv,

  darwin,
  # apple-sdk_14,
  # buildGoModule,
  fetchFromGitHub,
  git,
}:

stdenv.mkDerivation {
  pname = "gastown";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "steveyegge";
    repo = "gastown";
    rev = "main";
    hash = "sha256-OBacuL4Smb3gXVSlqmdMWUAy/Ky77ivupugc2dNgLc0=";
  };

  vendorHash = "sha256-ripY9vrYgVW8bngAyMLh0LkU/Xx1UUaLgmAA7/EmWQU=";

  subPackages = [ "cmd/gt" ];

  nativeBuildInputs = [
    git
    darwin.sigtool
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp gt $out/bin/
  '';

  postFixup = ''
    codesign --entitlements vf.entitlements -f -s - $out/bin/gt
  '';

  meta = with lib; {
    description = "Multi-agent orchestration system for Claude Code with persistent work tracking";
    homepage = "https://github.com/steveyegge/gastown";
    license = licenses.mit;
    platforms = lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    mainProgram = "gt";
  };
}
