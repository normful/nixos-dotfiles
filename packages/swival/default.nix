# swival – installed as a uv-locked virtualenv via uv2nix
# https://github.com/Swival/swival
#
# Why not `python314Packages.buildPythonApplication` with nixpkgs deps:
# swival 1.9.4's runtime closure is 102 packages. Against nixpkgs-unstable-2611
# (4fe25e1) 5 of them do not exist (fast-cipher, html-to-markdown,
# google-cloud-aiplatform; pywin32 and httpx2-jsfetch are platform-conditional
# no-ops on darwin) and 58 exist at a different version — several materially so
# (openai 2.53 vs 3.49, huggingface-hub 2.4 vs 1.33, tiktoken 0.12 vs 0.14,
# litellm 1.108.0 vs 1.108.4, starlette 1.7 vs 1.10, uvicorn 0.51 vs 0.54).
# Hand-maintaining that mapping means ~60 overrides that all break again on the
# next bump.
#
# Upstream's own Homebrew formula does `uv pip install <release tree>`, i.e. it
# resolves the dependency set from `uv.lock` and takes whatever PyPI serves.
# uv2nix does the same thing hermetically: it reads the release tree's lockfile
# at evaluation time, fetches each locked wheel/sdist from PyPI with a fixed
# hash, and links them into one virtualenv. Picks are upstream's, versions are
# upstream's.
#
# To bump:
#   1. Set `rev` below to the new tag.
#   2. Refresh `hash` with:
#        nix store prefetch-file --unpack --json \
#          https://github.com/Swival/swival/archive/refs/tags/<rev>.tar.gz
#   3. `nix build` this package and smoke-test `result/bin/swival --version`.
# There is no separate version string: it is read out of the fetched tree, so the
# tag and the version cannot disagree.
{
  lib,
  pkgs,
  uv2nix,
  pyproject-nix,
  pyproject-build-systems,
}: let
  src = pkgs.fetchFromGitHub {
    owner = "Swival";
    repo = "swival";
    rev = "1.9.4";
    hash = "sha256-DNNiXCvIGoZR9a2/shEDzzpGX3kfY7ISuk11dqXI0Fs=";
  };

  # Read the version from the tree itself rather than duplicating the tag in a
  # second string that can drift. This costs a second import-from-derivation
  # (uv2nix already realises this fetch to read `uv.lock`): the fetch has to
  # happen during evaluation before `pyproject.toml` can be read.
  version = (builtins.fromTOML (builtins.readFile "${src}/pyproject.toml")).project.version;

  # uv2nix reads `pyproject.toml` + `uv.lock` off this tree at evaluation time,
  # which is import-from-derivation: realising the fetch is part of evaluating
  # this expression. Both files come straight from the release tag, so the
  # dependency pins cannot drift from the code.
  workspace = uv2nix.lib.workspace.loadWorkspace {workspaceRoot = src;};

  # html-to-markdown 3.22.0 ships only `macosx_15_0_*` wheels for macOS, while
  # nixpkgs declares `darwinSdkVersion = "14.0"`, so pypa wheel selection rejects
  # the tag and falls back to the Rust/maturin sdist (which needs a full cargo
  # build). Raising the SDK version for this one package accepts the official
  # wheel. The hook rewrites MACOSX_DEPLOYMENT_TARGET to 15.0 for that wheel, so
  # the resulting module needs macOS >= 15 (host runs 26.x). Nothing else in the
  # closure is affected: the other 100 packages keep the default SDK version.
  stdenvSdk15 = pkgs.stdenv.override {
    targetPlatform = pkgs.stdenv.targetPlatform // {darwinSdkVersion = "15.0";};
  };

  overlay = pkgs.lib.composeManyExtensions [
    # `wheel` preference mirrors what an install does: use upstream binaries when
    # they exist instead of rebuilding sdists.
    (workspace.mkPyprojectOverlay {sourcePreference = "wheel";})
    (final: prev: {
      html-to-markdown = prev.html-to-markdown.override {stdenv = stdenvSdk15;};
    })
  ];

  pythonSet = (pkgs.callPackage pyproject-nix.build.packages {python = pkgs.python314;})
    .overrideScope (pkgs.lib.composeManyExtensions [
    pyproject-build-systems.overlays.default
    overlay
  ]);

  # `workspace.deps.default` = the main (runtime) dependency group only:
  # no pytest/ruff/dev extras. 104 distributions, ~1.9 GiB runtime closure.
  venv = pythonSet.mkVirtualEnv "swival-env" workspace.deps.default;
in
  venv.overrideAttrs (old: {
    name = "swival-${version}";

    meta =
      (old.meta or {})
      // {
        description = "A small, powerful CLI coding agent for open AI models";
        longDescription = ''
          Swival is a CLI coding agent built to be practical, reliable, and easy to use.
          It works with frontier models, but its main goal is to be as reliable as
          possible with smaller models, including local ones. Connects to LM Studio,
          llama.cpp, HuggingFace, OpenRouter, Google Gemini, ChatGPT, AWS Bedrock,
          and any OpenAI-compatible server.
        '';
        homepage = "https://swival.dev/";
        changelog = "https://github.com/Swival/swival/releases/tag/${version}";
        license = lib.licenses.mit;
        mainProgram = "swival";
        platforms = ["aarch64-darwin"];
      };
  })
