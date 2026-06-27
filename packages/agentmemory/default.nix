{
  lib,
  fetchurl,
  buildNpmPackage,
  fetchNpmDeps,
  makeWrapper,
  nodejs,
  cacert,
  runCommand,
}:

let
  version = "0.9.27";

  src = fetchurl {
    url = "https://registry.npmjs.org/@agentmemory/agentmemory/-/agentmemory-${version}.tgz";
    hash = "sha256-m5pgNaGo6+MEuvkrscWOIzfyRl147mO+vDZHU8D7KiU=";
  };

  # Pre-fetch only production dependencies (no devDeps, no TypeScript build).
  # npm tarball ships pre-built dist/ — no build step needed.
  npmDeps = fetchNpmDeps {
    name = "agentmemory-npm-deps";
    inherit src;
    sourceRoot = "package";
    hash = "sha256-FPLzg8jknhJV/ctaebLIGAJbDei4reFfAXsJo5MUl5A=";
    nativeBuildInputs = [ nodejs cacert ];

    # NOTE: generates lockfile with ALL deps (dev included) so fetchNpmDeps
    # caches the full transitive tree. npmInstallFlags below restricts to
    # production deps at install time.
    postPatch = ''
      HOME=$TMPDIR npm install --package-lock-only --ignore-scripts --legacy-peer-deps --no-audit --no-fund
    '';
  };
in
buildNpmPackage {
  pname = "agentmemory";
  inherit version src npmDeps;

  # npm tarball has package/ prefix
  sourceRoot = "package";

  # Already pre-built — just need runtime deps from npmDeps
  dontBuild = true;

  # Only install production deps (devDeps are only needed for lockfile gen)
  npmInstallFlags = [ "--production" ];

  # Avoid peer dep conflicts during install
  npmFlags = [ "--legacy-peer-deps" ];

  # Skip rebuild scripts — sharp's install downloads libvips from GitHub
  # and fails in the sandbox. Only needed for optional onnx dep anyway.
  npmRebuildFlags = [ "--ignore-scripts" ];

  # npm needs to write to cache during install
  makeCacheWritable = true;

  # npm tarball doesn't ship package-lock.json; copy from fetchNpmDeps output
  postPatch = ''
    cp ${npmDeps}/package-lock.json package-lock.json
  '';

  nodejs = nodejs;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/@agentmemory/agentmemory
    cp -r dist package.json node_modules $out/lib/node_modules/@agentmemory/agentmemory/
    cp -r iii-config.yaml docker-compose.yml .env.example \
      $out/lib/node_modules/@agentmemory/agentmemory/ 2>/dev/null || true
    [ -d plugin ] && cp -r plugin $out/lib/node_modules/@agentmemory/agentmemory/

    mkdir -p $out/bin
    makeWrapper ${nodejs}/bin/node \
      $out/bin/agentmemory \
      --add-flags "$out/lib/node_modules/@agentmemory/agentmemory/dist/cli.mjs"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Persistent memory for AI coding agents";
    longDescription = ''
      agentmemory provides persistent memory for AI coding agents.
      It silently captures what your agent does, compresses it into
      searchable memory, and injects the right context when the next
      session starts. Built on iii-engine primitives.
    '';
    homepage = "https://github.com/rohitg00/agentmemory";
    license = licenses.asl20;
    mainProgram = "agentmemory";
    platforms = [ "aarch64-darwin" ];
  };
}
