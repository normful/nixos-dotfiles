{
  lib,
  fetchFromGitHub,
  rustPlatform,
  perl,
}:

rustPlatform.buildRustPackage rec {
  pname = "arxiv-cli";
  # No release tags upstream — pinned to main commit below
  version = "0.2.0";

  # openssl-sys is built with the `vendored` feature, which compiles OpenSSL
  # from source inside cargo — that needs perl to run openssl's Configure.
  nativeBuildInputs = [ perl ];

  src = fetchFromGitHub {
    owner = "sonesuke";
    repo = "arxiv-cli";
    rev = "6b0d55142a791f564cd48b87aa6baa641e43278e";
    hash = "sha256-VoFHgGfjtZ2wcdJkZDA8GXW/HTkgKQp6y/3zM4n5NzM=";
  };

  # Vendors git deps (chrome-cdp, cypher-rs) from the lock file
  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "chrome-cdp-0.1.0" = "sha256-V3o8T33UnX/zi56S9E2Lt1VnEkDhafrprBPiaAXueQo=";
      "cypher-rs-0.1.0" = "sha256-qbzMT8j66p3+M6ic8+kc6p0232TCnMMOsPZu1VEWAdA=";
    };
  };

  doCheck = false; # e2e tests need a live Chrome + network

  meta = with lib; {
    description = "AI-ready search and fetch CLI for arXiv papers";
    longDescription = ''
      Search arXiv by free-text query and fetch paper details with extracted
      PDF text. Headless Chrome/Chromium required at runtime (CDP scraping);
      ships an MCP server mode (`arxiv-cli mcp`) for AI agents.
    '';
    homepage = "https://github.com/sonesuke/arxiv-cli";
    license = licenses.mit;
    mainProgram = "arxiv-cli";
    platforms = [ "aarch64-darwin" ];
  };
}
