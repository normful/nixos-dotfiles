{
  lib,
  fetchurl,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "fff-mcp";
  version = "0.9.6";

  src = fetchurl {
    url = "https://github.com/dmtrKovalenko/fff/releases/download/v${version}/fff-mcp-aarch64-apple-darwin";
    sha256 = "29a7fadeafb062f3e5954b1ab8c69e14dca24f5e061cd8d3b1ea1bab385a3754";
  };

  dontBuild = true;
  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp $src $out/bin/fff-mcp
    chmod +x $out/bin/fff-mcp
    runHook postInstall
  '';

  meta = with lib; {
    description = "High-performance file search MCP server for AI code assistants";
    longDescription = ''
      FFF MCP Server provides high-performance file search for AI coding agents
      via the Model Context Protocol. Typo-resistant path and content search,
      frecency-ranked file access, a background watcher, and a lightweight
      in-memory content index. Way faster than ripgrep and fzf in any
      long-running process that searches more than once.
    '';
    homepage = "https://github.com/dmtrKovalenko/fff";
    license = licenses.mit;
    mainProgram = "fff-mcp";
    platforms = [ "aarch64-darwin" ];
  };
}
