{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  makeWrapper,
  nodejs,
}:

buildNpmPackage rec {
  pname = "gnhf";
  version = "0.1.42";

  src = fetchFromGitHub {
    owner = "kunchenguid";
    repo = "gnhf";
    rev = "gnhf-v${version}";
    hash = "sha256-WgBOgOeCXG2gpBNvNWNwjL30AvnZqwAU2uBSbfh9aAk=";
  };

  npmDepsHash = "sha256-q2w+qgFsS7BYPqXpQhL0LvVysChzx/mF97OEBrDQewI=";

  # npm install from package.json works for this simple pnpm project
  # (single workspace root, no pnpm-specific features needed at install time).
  # buildNpmPackage runs `npm run build` which invokes tsdown.

  # Don't use npm's built-in install (which tries to `npm install -g` the
  # source dir). Instead copy dist + package.json and wrap with node.
  dontNpmInstall = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/gnhf
    cp -r dist package.json $out/lib/node_modules/gnhf/
    cp -r skills $out/lib/node_modules/gnhf/ 2>/dev/null || true

    mkdir -p $out/bin
    makeWrapper ${nodejs}/bin/node \
      $out/bin/gnhf \
      --add-flags "$out/lib/node_modules/gnhf/dist/cli.mjs"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Good Night Have Fun — before I go to bed, I tell my agents";
    longDescription = ''
      gnhf is a CLI tool that lets you send instructions to your AI agents
      before winding down. Built with Commander and js-yaml for configuration.
    '';
    homepage = "https://github.com/kunchenguid/gnhf";
    license = licenses.mit;
    mainProgram = "gnhf";
    platforms = [ "aarch64-darwin" ];
  };
}
