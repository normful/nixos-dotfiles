{
  lib,
  fetchurl,
  fetchFromGitHub,
  buildNpmPackage,
  nodejs,
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

  # The build script fetches litellm pricing data from the network.
  # Nix sandbox blocks network access, so we pre-fetch it here.
  litellmPrices = fetchurl {
    url = "https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json";
    hash = "sha256-NsiZTk1l7c/jlsZHN9kKoPfzA3hAZ6Jt/CCQmUxv3k0=";
  };

  preBuild = ''
    mkdir -p src/data
    node -e "
      const fs = require('fs');
      const raw = JSON.parse(fs.readFileSync('${litellmPrices}', 'utf8'));
      const snapshot = {};
      const entries = Object.entries(raw).filter(([k]) => k !== 'sample_spec');
      function toVal(e) {
        if (e.input_cost_per_token == null || e.output_cost_per_token == null) return null;
        return [e.input_cost_per_token, e.output_cost_per_token, e.cache_creation_input_token_cost ?? null, e.cache_read_input_token_cost ?? null];
      }
      for (const [n, e] of entries) {
        if (n.includes('/')) continue;
        const v = toVal(e);
        if (v) snapshot[n] = v;
      }
      for (const [n, e] of entries) {
        if (!n.includes('/')) continue;
        const v = toVal(e);
        if (!v) continue;
        if (!snapshot[n]) snapshot[n] = v;
        const s = n.replace(/^[^/]+\//, "");
        if (s !== n && !snapshot[s]) snapshot[s] = v;
      }
      snapshot['MiniMax-M2.7'] = [0.3e-6, 1.2e-6, 0.375e-6, 0.06e-6];
      snapshot['MiniMax-M2.7-highspeed'] = [0.6e-6, 2.4e-6, 0.375e-6, 0.06e-6];
      fs.writeFileSync('src/data/litellm-snapshot.json', JSON.stringify(snapshot));
    "
  '';

  # Skip the bundle-litellm step (data already provided above), just run tsup
  buildPhase = ''
    npx tsup
  '';

  meta = with lib; {
    description = "See where your AI coding tokens go - by task, tool, model, and project";
    homepage = "https://github.com/getagentseal/codeburn";
    license = licenses.mit;
    mainProgram = "codeburn";
    platforms = [ "aarch64-darwin" ];
  };
}
