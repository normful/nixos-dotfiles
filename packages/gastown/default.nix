{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
  git,
}:

buildGoModule {
  pname = "gastown";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "steveyegge";
    repo = "gastown";
    rev = "main";
    hash = "sha256-OBacuL4Smb3gXVSlqmdMWUAy/Ky77ivupugc2dNgLc0=";
  };

  vendorHash = "sha256-ripY9vrYgVW8bngAyMLh0LkU/Xx1UUaLgmAA7/EmWQU=";

  enableGoModuleCache = true;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/steveyegge/gastown/internal/cmd.Version=VersionTODO"
    "-X github.com/steveyegge/gastown/internal/cmd.Build=BuildTODO"
    "-X github.com/steveyegge/gastown/internal/cmd.Commit=CommitTODO"
    "-X github.com/steveyegge/gastown/internal/cmd.Branch=main"
  ];

  CGO_ENABLED = 1;

  subPackages = [ "cmd/gt" ];

  nativeBuildInputs = [ git ];

  preBuild = ''
    go generate ./...
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp gt $out/bin/
  '';

  meta = with lib; {
    description = "Multi-agent orchestration system for Claude Code with persistent work tracking";
    homepage = "https://github.com/steveyegge/gastown";
    license = licenses.mit;
    platforms = [
      "aarch64-darwin"
    ];
    mainProgram = "gt";
  };
}
