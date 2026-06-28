{
  lib,
  fetchFromGitHub,
  fetchPypi,
  python313Packages,
}:

let
  # ── doclang (dependency of docling-core v2.85.0, not in nixpkgs) ──────────
  doclang = python313Packages.buildPythonPackage rec {
    pname = "doclang";
    version = "0.7.0";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      sha256 = "199ji0bxr101lpyqlgs29yrlyz749yn5dwmkirxcy047kp2grj2q";
    };

    nativeBuildInputs = with python313Packages; [
      setuptools
    ];

    propagatedBuildInputs = with python313Packages; [
      lxml
      saxonche
      typer
    ];

    doCheck = false;
  };

  # Extend python313Packages so docling-core's `with python313Packages;` finds doclang
  pythonPkgs = python313Packages // { inherit doclang; };

  # ── docling-core v2.85.0 (nixpkgs ships v2.73.0, too old) ────────────────
  docling-core = pythonPkgs.buildPythonPackage rec {
    pname = "docling-core";
    version = "2.85.0";
    format = "pyproject";

    src = fetchFromGitHub {
      owner = "docling-project";
      repo = "docling-core";
      rev = "v${version}";
      hash = "sha256-HjPCGuP/1W14U+Jr5xOtH2wBhTY8yvcQL5wWXRMfNdM=";
    };

    nativeBuildInputs = with pythonPkgs; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with pythonPkgs; [
      defusedxml
      doclang
      jsonref
      jsonschema
      latex2mathml
      pandas
      pillow
      pydantic
      pydantic-settings
      pyyaml
      tabulate
      typer
      typing-extensions
    ];

    # nixpkgs has defusedxml 0.8.0rc2 (docling-core requires <0.8.0)
    # and pydantic-settings 2.12.0 (requires >=2.14.0)
    dontCheckRuntimeDeps = true;
    pythonImportsCheck = [ "docling_core" ];

    doCheck = false;
  };
in

python313Packages.buildPythonApplication rec {
  pname = "docling-slim";
  version = "2.107.0";
  format = "other";

  src = fetchFromGitHub {
    owner = "docling-project";
    repo = "docling";
    rev = "v${version}";
    hash = "sha256-66banfdEn7uSH2En9YkyfqEt9dERzH8wSMRRBJ0pHEY=";
  };

  # pyproject.toml and docling/ source are at repo root (monorepo root = docling-slim)
  setSourceRoot = "sourceRoot=source";

  nativeBuildInputs = with python313Packages; [
    hatchling
    build
    installer
  ];

  buildPhase = ''
    runHook preBuild
    python -m build --no-isolation --outdir dist/ --wheel
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    python -m installer --prefix "$out" dist/*.whl
    runHook postInstall
  '';

  propagatedBuildInputs = with python313Packages; [
    # Core deps
    pydantic
    docling-core
    pydantic-settings
    filetype
    requests
    certifi
    pluggy
    tqdm
    # CLI deps
    typer
    rich
    # convert-core deps
    numpy
    pillow
    scipy
    rtree
    # format-pdf (pypdfium2 only; docling-parse is broken in nixpkgs)
    pypdfium2
    # format-office deps
    python-docx
    python-pptx
    openpyxl
    # format-email deps
    mail-parser
    # format-web deps
    beautifulsoup4
    lxml
    marko
    # format-latex deps
    pylatexenc
    # extract-core deps
    polyfactory
    # models deps
    torch
    torchvision
    docling-ibm-models
    accelerate
    huggingface-hub
    defusedxml
    # service-client deps
    httpx
    websockets
    # chunking deps (via docling-core[chunking])
    typing-extensions
    # OCR deps (RapidOCR)
    rapidocr
    onnxruntime
  ];

  # Patch imports to make docling_parse optional since
  # docling-parse is broken in nixpkgs (C++ build fails with nlohmann_json 3.12)
  postInstall = ''
    site=$out/${python313Packages.python.sitePackages}

    # Replace docling_parse_backend with a stub that doesn't import docling_parse
    cat > "$site/docling/backend/docling_parse_backend.py" << 'STUB'
import logging
from docling.backend.pypdfium2_backend import PyPdfiumDocumentBackend

_log = logging.getLogger(__name__)


class DoclingParseDocumentBackend(PyPdfiumDocumentBackend):
    """Stub: docling-parse not available, falling back to pypdfium2 backend."""
    pass


class ThreadedDoclingParseDocumentBackend(PyPdfiumDocumentBackend):
    """Stub: docling-parse not available, falling back to pypdfium2 backend."""
    pass
STUB

    # Make DoclingParseDocumentBackend import optional in CLI
    sed -i '/^from docling\.backend\.docling_parse_backend import ($/,/^)$/c\
try:\
    from docling.backend.docling_parse_backend import (\
        DoclingParseDocumentBackend,\
        ThreadedDoclingParseDocumentBackend,\
    )\
except ImportError:\
    DoclingParseDocumentBackend = None\
    ThreadedDoclingParseDocumentBackend = None' "$site/docling/cli/main.py"
  '';

  # Many transitive deps may not be in nixpkgs;
  # skip strict runtime dependency checking.
  dontCheckRuntimeDeps = true;

  # docling-ibm-models bundles its own docling-core 2.73.0;
  # we use 2.85.0 directly — each resolves independently at runtime.
  dontUsePythonCatchConflicts = true;

  # Tests require network access and model downloads
  doCheck = false;

  meta = with lib; {
    description = "SDK and CLI for parsing PDF, DOCX, HTML, and more to unified document representation";
    homepage = "https://github.com/docling-project/docling";
    license = licenses.mit;
    mainProgram = "docling";
    platforms = [ "aarch64-darwin" ];
  };
}
