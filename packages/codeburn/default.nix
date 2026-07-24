{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
}:

buildNpmPackage rec {
  pname = "codeburn";
  version = "0.9.14";

  src = fetchFromGitHub {
    owner = "getagentseal";
    repo = "codeburn";
    rev = "v${version}";
    hash = "sha256-8B3dAJLZ1ntvYvuJVIW1VBGA7xB+DZ3yFHQIJNSzbE8=";
  };

  npmDepsHash = "sha256-TSoz72VUsvpEby7VQ9T/qp8fI3J8Ra/+QPGuCBvW5FA=";

  # Self-hosted seed data files so tsup can resolve static imports.
  # Runtime loadPricing() fetches live from LiteLLM on first CLI invocation.
  buildPhase = ''
    runHook preBuild
    mkdir -p src/data
    echo '{}' > src/data/litellm-snapshot.json
    echo '{}' > src/data/pricing-fallback.json
    npx tsup
    cp src/cli.ts dist/cli.js
    chmod +x dist/cli.js
    runHook postBuild
  '';

  meta = with lib; {
    description = "See where your AI coding tokens go - by task, tool, model, and project";
    homepage = "https://github.com/getagentseal/codeburn";
    license = licenses.mit;
    mainProgram = "codeburn";
    platforms = [ "aarch64-darwin" ];
  };
}
