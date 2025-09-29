{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  bun,
  bash,
}:

buildNpmPackage rec {
  pname = "grok-cli";
  version = "0.0.30";

  src = fetchFromGitHub {
    owner = "superagent-ai";
    repo = "grok-cli";
    tag = "@vibe-kit/grok-cli@${version}";
    hash = "sha256-78w5rU5kJV1AiLaDJPFWDpIcnPNKhDt5bZLRBY1mq/E=";
  };

  npmDepsHash = "sha256-Yl51fCnI3soQ4sGBg4dr+kVak8zYEkMTgyUKDaRK6N0=";

  nativeBuildInputs = [ bun ];
  buildInputs = [ bun ];

  buildPhase = ''
    bun run build
  '';

  installPhase = ''
    mkdir -p $out/bin $out/dist
    cp -r dist/* $out/dist/

    cat > $out/bin/grok <<EOF
    #!${bash}/bin/bash
    exec ${bun}/bin/bun $out/dist/index.js "\$@"
    EOF

    chmod +x $out/bin/grok
  '';

  meta = with lib; {
    description = "An open-source AI agent that brings the power of Grok directly into your terminal.";
    homepage = "https://github.com/superagent-ai/grok-cli";
    license = licenses.mit;
    mainProgram = "grok";
  };
}
