{
  lib,
  fetchFromGitHub,
  fetchurl,
  python313Packages,
}:

let
  # thop — declared dep of doclayout-yolo (FLOPs profiler), missing from nixpkgs.
  # Published only as a wheel; pure-Python, torch-only dep.
  thop = python313Packages.buildPythonPackage rec {
    pname = "thop";
    version = "0.1.1.post2209072238";
    format = "wheel";

    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/bb/0f/72beeab4ff5221dc47127c80f8834b4bcd0cb36f6ba91c0b1d04a1233403/thop-0.1.1.post2209072238-py3-none-any.whl";
      hash = "sha256-AUc8IlIxkn0q1xg1H3jr98/+avO+1GTE8boe8PfN2ic=";
    };

    # Pure wheel — nothing to build. Without this, the ninja setup-hook
    # (inherited via torch's build inputs) hijacks the build phase.
    dontBuild = true;

    propagatedBuildInputs = [ python313Packages.torch ];

    doCheck = false;
  };

  # doclayout-yolo — figure/table/equation detection, missing from nixpkgs.
  # Published only as a wheel; the agent-papers-cli [layout] extra uses it.
  doclayout-yolo = python313Packages.buildPythonPackage rec {
    pname = "doclayout-yolo";
    version = "0.0.4";
    format = "wheel";

    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/7e/ac/6e16e92f412d94494f6fed95cfdf3ff135cf09af09e4d4f10846e9d87f75/doclayout_yolo-0.0.4-py3-none-any.whl";
      hash = "sha256-k0RROFpuUNcfu9oS5YZutAA9hxhjZNAVHY6OyJiiFyM=";
    };

    # Pure wheel — nothing to build. Without this, the ninja setup-hook
    # (inherited via torch's build inputs) hijacks the build phase.
    dontBuild = true;

    propagatedBuildInputs =
      (with python313Packages; [
        matplotlib
        opencv-python
        pillow
        pyyaml
        requests
        scipy
        torch
        torchvision
        tqdm
        psutil
        py-cpuinfo
        pandas
        seaborn
        albumentations
      ])
      ++ [ thop ];

    dontCheckRuntimeDeps = true;

    doCheck = false;
  };

  pythonPkgs = python313Packages // {
    inherit thop doclayout-yolo;
  };
in

pythonPkgs.buildPythonApplication rec {
  pname = "agent-papers-cli";
  version = "0.2.1";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "collaborative-deep-research";
    repo = "agent-papers-cli";
    rev = "v${version}";
    hash = "sha256-YlREHbqOPelbQL+kGDqojHrMUPt1nq0+sw+b8uJUjUQ=";
  };

  nativeBuildInputs = with pythonPkgs; [
    hatchling
  ];

  propagatedBuildInputs = with pythonPkgs; [
    click
    httpx
    pymupdf
    pysbd
    rich
    tenacity
    python-dotenv
    # [layout] extra — figure/table/equation detection
    doclayout-yolo
    huggingface-hub
  ];

  # Some nixpkgs versions trail upstream constraints; the package also
  # imports doclayout_yolo lazily so heavy layout deps aren't needed at
  # import time.
  dontCheckRuntimeDeps = true;

  doCheck = false;

  meta = with lib; {
    description = "Read, search, and cite academic papers from the CLI — built for agentic deep research";
    longDescription = ''
      Two CLI tools for academic research workflows:
      - `paper` — read, skim, search, and navigate PDFs (outline, goto,
        highlight, bibtex, figure/table/equation detection with layout extra)
      - `paper-search` — search Google (via Serper), Google Scholar, Semantic
        Scholar, and PubMed; browse webpages via Jina/Serper
      Built for agentic deep research; ships Claude Code skills upstream.
      PDFs cached in ~/.papers/.
    '';
    homepage = "https://github.com/collaborative-deep-research/agent-papers-cli";
    license = licenses.asl20;
    mainProgram = "paper";
    platforms = [ "aarch64-darwin" ];
  };
}
