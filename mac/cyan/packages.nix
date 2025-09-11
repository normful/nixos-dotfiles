{ pkgs-stable, pkgs-pinned-unstable, ... }:

let
  better-adb-sync = pkgs-stable.callPackage ../../packages/better-adb-sync { };
  carbonyl = pkgs-pinned-unstable.callPackage ../../packages/carbonyl { };
in
(with pkgs-stable; [
  #################################################################################
  # Shell scripting
  #################################################################################

  # https://xon.sh/tutorial.html
  # Examples of .xsh code: https://github.com/search?q=language%3AXonsh&type=code
  xonsh # TODO: Add to `modules`

  /*
    Aim to use:
    fish for interactive usage
    xonsh for scripting
  */

  #################################################################################
  # Bash
  #################################################################################

  bats # TODO: add to `modules`
  shfmt # TODO: add to `modules`

  #################################################################################
  # Git
  #################################################################################

  git
  gh

  #################################################################################
  # Jujutsu TODO: add to `modules`
  #################################################################################

  jujutsu
  lazyjj

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  #~~~~TODO~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  #~~~~~Below this line, most packages need to be placed into `modules`~~~~~~~~~~~~
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  #################################################################################
  # Tools for multiple languages
  #################################################################################

  # https://gcc.gnu.org
  gcc

  # https://just.systems/man/en/
  just

  # https://cmake.org/cmake/help/latest/
  cmake

  # https://docs.ctags.io/en/latest/
  universal-ctags

  # https://github.com/mattn/efm-langserver
  efm-langserver

  # https://github.com/cortesi/modd
  modd

  # https://espanso.org/docs/get-started/
  # https://espanso.org/docs/packages/basics/
  # https://hub.espanso.org/search
  espanso

  #################################################################################
  # Ruby
  #################################################################################

  (ruby.withPackages (
    pks: with pks; [
      rubocop
      nokogiri
      pry
      neovim
    ]
  ))

  #################################################################################
  # Lua
  #################################################################################

  (lua5_1.withPackages (
    pks: with pks; [
      luarocks
    ]
  ))
  stylua

  #################################################################################
  # PHP
  #################################################################################

  php
  php84Packages.composer
  php84Extensions.xdebug
  intelephense

  #################################################################################
  # Regular expressions
  #################################################################################

  # https://pemistahl.github.io/grex-js/
  # https://github.com/pemistahl/grex?tab=readme-ov-file#51-the-command-line-tool
  grex

  #################################################################################
  # JSON
  #################################################################################

  # https://jqlang.org
  jq

  # https://jless.io/user-guide
  jless

  # https://github.com/adamritter/fastgron
  fastgron

  # https://github.com/Stranger6667/jsonschema
  jsonschema-cli

  #################################################################################
  # CSS
  #################################################################################

  # https://stylelint.io/user-guide/configure
  stylelint

  #################################################################################
  # TOML
  #################################################################################

  # https://taplo.tamasfe.dev/cli/introduction.html
  taplo

  #################################################################################
  # Nix
  #################################################################################

  # https://taplo.tamasfe.dev/cli/introduction.html
  nixfmt-rfc-style

  #################################################################################
  # Log files
  #################################################################################

  # https://docs.lnav.org/en/latest/index.html
  lnav

  # https://github.com/pamburus/hl
  hl-log-viewer

  #################################################################################
  # UML Diagrams
  #################################################################################

  # https://plantuml.com
  plantuml

  #################################################################################
  # Images
  #################################################################################

  # https://inkscape.org
  inkscape

  # https://usage.imagemagick.org
  imagemagick

  # https://pmt.sourceforge.io/pngcrush/
  pngcrush

  #################################################################################
  # Audio and video libraries
  #################################################################################

  # https://www.ffmpeg.org/documentation.html
  ffmpeg

  # https://xiph.org/vorbis/
  vorbis-tools

  #################################################################################
  # Audio and video players
  #################################################################################

  # https://musikcube.com
  # I like this one more than cmus, and more than many others I tried
  musikcube

  #################################################################################
  # Typesetting (TeX, LaTeX, Typst)
  #################################################################################

  # https://www.tug.org/texlive/doc.html
  texliveSmall

  # https://github.com/typst/typst
  typst

  # https://github.com/Myriad-Dreamin/tinymist
  tinymist

  # https://github.com/Bzero/typstwriter
  typstwriter

  # https://pandoc.org/MANUAL.html
  pandoc

  #################################################################################
  # PDF
  #################################################################################

  # https://ghostscript.readthedocs.io/en/latest/Use.html
  ghostscript

  # https://qpdf.readthedocs.io/en/stable/
  qpdf

  /*
    Use Ghostscript when:

    Converting PDFs to images or other formats
    Processing PostScript files
    Need aggressive compression for web delivery
    Working with mixed document types
    Dealing with rendering-related issues

    Use qpdf when:

    Need to preserve exact PDF structure and quality
    Performing encryption/security operations
    Splitting, merging, or reorganizing pages frequently
    Need detailed PDF inspection and debugging
    Working with large files where performance matters
    Repairing corrupted PDFs
  */

  # GUI to visually diff PDFs
  # https://vslavik.github.io/diff-pdf/
  diff-pdf

  #################################################################################
  # DNS lookups
  #################################################################################

  # https://github.com/ogham/dog
  dogdns

  # https://github.com/ameshkov/dnslookup
  dnslookup

  # https://mhost.pustina.de/docs/usage_examples
  mhost

  #################################################################################
  # Downloading files
  #################################################################################

  # https://everything.curl.dev
  # https://www.mankier.com/1/curl
  curl

  # https://www.gnu.org/software/wget/manual/wget.html
  wget

  # https://rockdaboot.github.io/wget2/md_wget2_manual.html
  wget2

  # https://github.com/ducaale/xh#usage
  xh

  #################################################################################
  # gRPC
  #################################################################################

  # https://github.com/fullstorydev/grpcurl?tab=readme-ov-file#usage
  grpcurl

  #################################################################################
  # Syncing files
  #################################################################################

  # https://download.samba.org/pub/rsync/rsync.1
  # https://www.mankier.com/1/rsync
  rsync

  # https://rclone.org
  rclone

  # https://lftp.yar.ru/lftp-man.html
  lftp

  # https://github.com/jb2170/better-adb-sync
  better-adb-sync

  #################################################################################
  # Screen sharing
  #################################################################################

  # https://github.com/Genymobile/scrcpy
  scrcpy

  # https://wiki.archlinux.org/title/Remmina
  remmina

  #################################################################################
  # Secrets management
  #################################################################################

  # https://infisical.com/docs/cli/usage
  infisical

  #################################################################################
  # Others
  #################################################################################

  # https://docs.openssl.org/master/man1/openssl/
  openssl

  # https://github.com/tailscale/tailscale
  tailscale

  # https://getsops.io/docs/
  sops

  # https://github.com/FiloSottile/age
  age

  # https://mise.jdx.dev
  mise

  # https://sources.debian.org/src/whois/5.6.4/mkpasswd.c
  mkpasswd

  # https://restic.readthedocs.io/en/stable/
  restic

  # https://github.com/abiosoft/colima#usage
  colima

  # https://www.getzola.org/documentation/getting-started/cli-usage/
  zola

  # https://github.com/sharkdp/hyperfine#usage
  hyperfine

  # https://docs.cointop.sh
  cointop

  # https://www.tcpdump.org/manpages/tcpdump.1.html
  tcpdump

  # https://github.com/tuxera/ntfs-3g
  ntfs3g

  # https://github.com/sharkdp/pastel#use-cases-and-demo
  pastel

  # https://graphviz.org
  graphviz

  # https://github.com/julienXX/terminal-notifier
  terminal-notifier

  # https://github.com/denisidoro/navi
  navi
])

++ (with pkgs-pinned-unstable; [
  #################################################################################
  # Nix
  #################################################################################

  nix-prefetch-github

  #################################################################################
  # Rust
  #################################################################################

  rustup

  #################################################################################
  # TypeScript and JavaScript
  #################################################################################

  nodejs

  # https://docs.deno.com
  deno

  # https://bun.sh
  bun

  yarn
  nodePackages.prettier
  prettierd
  eslint_d

  #################################################################################
  # Python
  #################################################################################

  uv
  (python312.withPackages (
    pks: with pks; [
      isort
      pyflakes
      pylint
      pynvim
      numpy
    ]
  ))
  poetry

  #################################################################################
  # Golang
  #################################################################################

  go
  gopls
  gotools
  protoc-gen-go
  cobra-cli
  golangci-lint

  #################################################################################
  # Gleam
  #################################################################################

  # https://gleam.run/documentation/
  gleam

  #################################################################################
  # Erlang
  #################################################################################

  # https://www.erlang.org/doc/man_index.html
  beam.packages.erlang_28.erlang

  # https://rebar3.org/docs/
  beam.packages.erlang_28.rebar3

  #################################################################################
  # AI coding agents from the big companies
  #################################################################################

  # https://docs.anthropic.com/en/docs/claude-code/overview
  # Run latest version with bunx, not the Nix pkg

  # https://github.com/google-gemini/gemini-cli#-documentation
  # Run latest version with bunx, not the Nix pkg

  # https://github.com/QwenLM/qwen-code
  # Run latest version with bunx, not the Nix pkg

  # https://github.com/openai/codex
  # Run latest version with bunx, not the Nix pkg

  #################################################################################
  # Open source AI coding agents you can use with any model
  #################################################################################

  # https://github.com/sst/opencode
  # Run latest version with bunx, not the Nix pkg

  # https://github.com/charmbracelet/crush
  # Run latest version with bunx, not the Nix pkg

  #################################################################################
  # Other AI-powered tools
  #################################################################################

  # https://github.com/di-sukharev/opencommit
  opencommit

  # https://repomix.com
  repomix

  #################################################################################
  # Misc
  #################################################################################

  carbonyl
])
