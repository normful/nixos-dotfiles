{
  lib,
  buildGoModule,
  fetchFromGitHub,
  versionCheckHook,
  git,
}:

buildGoModule rec {
  pname = "beads";
  version = "0.49.5";

  src = fetchFromGitHub {
    owner = "steveyegge";
    repo = "beads";
    rev = "v${version}";
    hash = "sha256-mqtHYUlx69EAZV6EsVffYFXz5E8mg6hojJpT79uoujc=";
  };

  # Git is required for tests
  nativeBuildInputs = [ git ];

  vendorHash = "sha256-deLPoWXRsWAyehUn2QlXA/vs7zepUF3jAjUq+MFCGbI=";

  subPackages = [ "cmd/bd" ];
  doCheck = false;
  doInstallCheck = true;

  # Allow Go toolchain to auto-download newer version if needed
  # (go.mod requires 1.25.6+ but nixpkgs may have older)
  env.GOTOOLCHAIN = "auto";

  nativeInstallCheckInputs = [ versionCheckHook ];

  meta = with lib; {
    description = "beads (bd) - An issue tracker designed for AI-supervised coding workflows";
    homepage = "https://github.com/steveyegge/beads";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "bd";
  };
}
