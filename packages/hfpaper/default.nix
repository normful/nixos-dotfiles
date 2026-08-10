{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:

buildGoModule rec {
  pname = "hfpaper";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "zakelfassi";
    repo = "hfpaper";
    rev = "v${version}";
    hash = "sha256-49Auy+e5WdIQU9UN4QDVznjWvo1TdlrVcuGxuR4E2fI=";
  };

  vendorHash = "sha256-C/3rtaW9Xlw6AZTyZKJecl8Ad5Kb0X+GcyQnWYYFP9s=";

  doCheck = false;

  meta = with lib; {
    description = "AI research papers from your terminal — search, read, cite, and explore Hugging Face Papers";
    longDescription = ''
      hfpaper is a CLI for searching, reading, citing, and exploring the Hugging
      Face Papers ecosystem. Semantic + full-text search across 500K+ papers,
      paper metadata with AI summaries, daily trending, BibTeX/APA/MLA citations,
      and linked HF models/datasets/spaces. Also ships an MCP server (hfpaper mcp)
      with 7 tools: search_papers, get_paper, read_paper, daily_papers,
      paper_models, paper_datasets, paper_spaces.
    '';
    homepage = "https://github.com/zakelfassi/hfpaper";
    license = licenses.mit;
    mainProgram = "hfpaper";
    platforms = [ "aarch64-darwin" ];
  };
}
