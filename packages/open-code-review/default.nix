{
  lib,
  fetchurl,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "open-code-review";
  version = "1.6.4";

  src = fetchurl {
    url = "https://github.com/alibaba/open-code-review/releases/download/v${version}/opencodereview-darwin-arm64";
    sha256 = "3733e41eb895dc396cf779a5827c5d9f2bef7f1ab8ff5a7f6a09787bc5c173e4";
  };

  dontBuild = true;
  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/ocr
    chmod +x $out/bin/ocr
  '';

  meta = with lib; {
    description = "AI-powered code review CLI with line-level precision";
    longDescription = ''
      Open Code Review is an AI-powered code review tool that reads Git diffs
      and sends changed files to a configurable LLM (OpenAI or Anthropic) for
      structured review comments with line-level precision. Features built-in
      rule sets (NPE, thread-safety, XSS, SQL injection), workspace and branch
      range review, WebUI viewer, and CI/CD integration.
    '';
    homepage = "https://github.com/alibaba/open-code-review";
    license = licenses.asl20;
    mainProgram = "ocr";
    platforms = [ "aarch64-darwin" ];
  };
}
