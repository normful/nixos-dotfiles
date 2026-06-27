{
  lib,
  fetchFromGitHub,
  runCommand,
  buildNpmPackage,
  fetchNpmDeps,
  makeWrapper,
  nodejs,
}:

let
  version = "3.1.0";

  srcOrig = fetchFromGitHub {
    owner = "pbakaus";
    repo = "impeccable";
    rev = "cli-v${version}";
    hash = "sha256-U6Eukc+xT4xX/jA3IVNB42p7Eey2XDbK6l5LHSTATX8=";
  };

  # Inject the package-lock.json into source — buildNpmPackage needs it for offline install
  src = runCommand "impeccable-src" { } ''
    cp -r ${srcOrig} $out
    chmod +w $out
    cp ${./package-lock.json} $out/package-lock.json
  '';

  # Pre-fetched npm dependencies — no network in sandbox
  npmDepsSrc = runCommand "npm-deps-src" { } ''
    mkdir -p $out
    cp ${./package-lock.json} $out/package-lock.json
  '';
  npmDeps = fetchNpmDeps {
    name = "impeccable-npm-deps";
    src = npmDepsSrc;
    hash = "sha256-c/XWs/gVOlBrIqMTcPpKKf1PyGQ6BCMMN3WgP0PML0U=";
  };
in
buildNpmPackage {
  pname = "impeccable";
  inherit version src npmDeps;

  nativeBuildInputs = [ makeWrapper ];

  # Suppress browser downloads during npm install (puppeteer, playwright)
  PUPPETEER_SKIP_BROWSER_DOWNLOAD = 1;
  PUPPETEER_SKIP_DOWNLOAD = 1;
  PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = 1;

  # No npm build step — just install deps and copy files
  dontNpmBuild = true;
  dontNpmPrune = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/impeccable
    # Strip bun's .cache — created if --no-save is not fully effective
    rm -rf node_modules/.cache 2>/dev/null || true
    cp -r cli package.json node_modules $out/lib/node_modules/impeccable/

    mkdir -p $out/bin
    makeWrapper ${nodejs}/bin/node \
      $out/bin/impeccable \
      --add-flags "$out/lib/node_modules/impeccable/cli/bin/cli.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Design guidance for AI coding agents";
    longDescription = ''
      Design skills, commands, and anti-pattern detection for AI coding agents.
      1 skill, 23 commands, live browser iteration, and 44 deterministic detector
      rules for AI-generated frontend design.
    '';
    homepage = "https://impeccable.style";
    license = licenses.asl20;
    mainProgram = "impeccable";
    platforms = [ "aarch64-darwin" ];
  };
}
