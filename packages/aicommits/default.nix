{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  makeWrapper,
  nodejs,
}:

buildNpmPackage rec {
  pname = "aicommits";
  version = "3.4.0";

  src = fetchFromGitHub {
    owner = "Nutlope";
    repo = "aicommits";
    rev = "v${version}";
    hash = "sha256-xh7TM3ThajeOXYCj2Vc246u3kYxA1VCHFWM4QbM8DGo=";
  };

  npmDepsHash = "sha256-iw7zz+jr39Ip8lZi5XS1E9T7FSSYAwND3JF4mSC5D4M=";

  nodejs = nodejs;

  # prepack runs `pnpm build && clean-pkg-json` (not available), install manually
  dontNpmInstall = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/aicommits
    cp -r dist package.json $out/lib/node_modules/aicommits/

    mkdir -p $out/bin
    makeWrapper ${nodejs}/bin/node \
      $out/bin/aicommits \
      --add-flags "$out/lib/node_modules/aicommits/dist/cli.mjs"
    ln -s aicommits $out/bin/aic

    runHook postInstall
  '';

  meta = with lib; {
    description = "A CLI that writes your git commit messages for you with AI";
    longDescription = ''
      A CLI that writes your git commit messages for you with AI.
      Never write a commit message again. Generates commit messages from
      staged git diff using various AI providers (TogetherAI, OpenAI,
      Groq, Ollama, etc.).
    '';
    homepage = "https://github.com/Nutlope/aicommits";
    license = licenses.mit;
    mainProgram = "aicommits";
    platforms = [ "aarch64-darwin" ];
  };
}
