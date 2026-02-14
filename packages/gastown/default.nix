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

  vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  ldflags =[

  ]

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
