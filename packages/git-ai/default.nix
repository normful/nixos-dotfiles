{
  lib,
  fetchFromGitHub,
  rustPlatform,
  openssl,
  sqlite,
  pkg-config,
  stdenv,
  libiconv,
  apple-sdk_15,
}:

rustPlatform.buildRustPackage rec {
  pname = "git-ai";
  version = "1.6.4";

  src = fetchFromGitHub {
    owner = "git-ai-project";
    repo = "git-ai";
    rev = "11d9468a7f4cf22772c157937f1375d7219884fa";
    hash = "sha256-BkJuBKmL6QrxtsVrpaXWK95gU1JfWSY2xG+WbASlbQE=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  # Prevent openssl-sys from vendoring OpenSSL (which requires perl).
  # Link against system OpenSSL provided by buildInputs.
  OPENSSL_NO_VENDOR = "1";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
    sqlite
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    libiconv
    apple-sdk_15
  ];

  doCheck = false;

  meta = with lib; {
    description = "AI-powered Git extension that tracks AI-generated code in your repos";
    longDescription = ''
      Git AI is an open source git extension that tracks the AI-generated code
      in your repositories. Every line of AI code is linked to the agent, model,
      and prompts that generated it — so you never lose the intent, requirements,
      and architecture decisions behind your code. Provides git-ai blame, commit
      tracking, and authorship attribution.
    '';
    homepage = "https://github.com/git-ai-project/git-ai";
    license = licenses.gpl3Plus;
    mainProgram = "git-ai";
    platforms = [ "aarch64-darwin" ];
  };
}
