{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}:

buildGoModule rec {
  pname = "grepai";
  version = "0.30.0";

  src = fetchFromGitHub {
    owner = "yoanbernabeu";
    repo = "grepai";
    rev = "v${version}";
    hash = "sha256-FeaPjzPmgbUrNcjV9CyXUqz0jp6oC11ukUnkszpL5Cc=";
  };

  vendorHash = "sha256-uHsx6l7k7ur295+DFGNUAvRG3j8K6uOKipyVCNtd0hs=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  meta = with lib; {
    description = "AI-powered semantic code search tool";
    homepage = "https://github.com/yoanbernabeu/grepai";
    license = licenses.mit;
    mainProgram = "grepai";
  };
}
