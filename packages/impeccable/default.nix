{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  fetchNpmDeps,
  makeWrapper,
  nodejs,
  cacert,
}:

let
  version = "3.1.0";

  src = fetchFromGitHub {
    owner = "pbakaus";
    repo = "impeccable";
    rev = "cli-v${version}";
    hash = "sha256-U6Eukc+xT4xX/jA3IVNB42p7Eey2XDbK6l5LHSTATX8=";
  };

  # Generate package-lock.json from upstream's bun.lock, then pre-fetch deps
  npmDeps = fetchNpmDeps {
    name = "impeccable-npm-deps";
    inherit src;
    hash = "sha256-Wwon4IEm79ybLl0nDQ+7nj+qXeYVzr4csBiIecLNMaM=";
    nativeBuildInputs = [ nodejs cacert ];

    postPatch = ''
      HOME=$TMPDIR npm install --package-lock-only --ignore-scripts --legacy-peer-deps --no-audit --no-fund
    '';
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

  # Avoid peer dep conflicts during install
  npmFlags = [ "--legacy-peer-deps" ];

  # npm needs to write to cache during install
  makeCacheWritable = true;

  # Copy generated lockfile from npmDeps into source so npm install finds it
  postPatch = ''
    cp ${npmDeps}/package-lock.json package-lock.json
  '';

  # No npm build step — CLI files are plain JS ESM
  dontNpmBuild = true;
  dontNpmPrune = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/impeccable
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
