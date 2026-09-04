{
  lib,
  fetchurl,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "humanify";
  version = "3.1.1";

  src = fetchurl {
    url = "https://github.com/jehna/humanify/releases/download/v${version}/humanify-aarch64-apple-darwin.tar.gz";
    sha256 = "430aae3e4d73f5305dd77a1ef9dc10613264066ddd4a1592fb14e56c1717ba88";
  };

  dontBuild = true;
  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin humanify
    chmod +x $out/bin/humanify
    runHook postInstall
  '';

  meta = with lib; {
    description = "Deobfuscate and reverse-engineer JavaScript using LLMs";
    longDescription = ''
      Humanify uses an LLM (OpenAI, Gemini, OpenRouter, Requesty, or local
      Ollama) to deobfuscate JavaScript: rename minified variables, inline
      functions, and restore readable structure. Useful for reading
      minified bundles, CTFs, and malware analysis.
    '';
    homepage = "https://github.com/jehna/humanify";
    license = licenses.mit;
    mainProgram = "humanify";
    platforms = [ "aarch64-darwin" ];
  };
}
