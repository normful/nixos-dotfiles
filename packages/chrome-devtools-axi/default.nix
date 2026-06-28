{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  makeWrapper,
  nodejs,
}:

buildNpmPackage rec {
  pname = "chrome-devtools-axi";
  version = "0.1.25";

  src = fetchFromGitHub {
    owner = "kunchenguid";
    repo = "chrome-devtools-axi";
    rev = "chrome-devtools-axi-v${version}";
    hash = "sha256-bV6FrZaUbereUgw4cqlXMsPREqjZnp6GxstccpHW6wY=";
  };

  npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  # Upstream uses pnpm (pnpm-lock.yaml), but buildNpmPackage requires
  # package-lock.json. Generate one from package.json so npm install works.
  postPatch = ''
    npm install --package-lock-only --ignore-scripts
  '';

  # Don't use npm's built-in install (which tries to `npm install -g` the
  # source dir). Instead copy dist + package.json and wrap with node.
  dontNpmInstall = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/node_modules/chrome-devtools-axi"
    cp -r dist package.json "$out/lib/node_modules/chrome-devtools-axi/"
    cp -r skills "$out/lib/node_modules/chrome-devtools-axi/" 2>/dev/null || true

    mkdir -p "$out/bin"
    makeWrapper "${nodejs}/bin/node" \
      "$out/bin/chrome-devtools-axi" \
      --add-flags "$out/lib/node_modules/chrome-devtools-axi/dist/bin/chrome-devtools-axi.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "The most agent-ergonomic browser automation";
    longDescription = ''
      AXI-compliant chrome-devtools-mcp wrapper — combined operations,
      TOON output, contextual suggestions. The most agent-ergonomic
      browser automation CLI, wrapping Chrome DevTools Protocol for AI
      coding agents.
    '';
    homepage = "https://github.com/kunchenguid/chrome-devtools-axi";
    license = licenses.mit;
    mainProgram = "chrome-devtools-axi";
    platforms = [ "aarch64-darwin" ];
  };
}
