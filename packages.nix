{ pkgs-stable, pkgs-pinned-unstable, ... }:

let
  better-adb-sync = pkgs-stable.callPackage ./packages/better-adb-sync.nix { };
  carbonyl = pkgs-pinned-unstable.callPackage ./packages/carbonyl.nix { };
  neovimLuaRc = pkgs-pinned-unstable.callPackage ./nix-nvim/customRC.vim.nix { };

  unstableNeovim = pkgs-pinned-unstable.neovim.override {
    # https://github.com/NixOS/nixpkgs/blob/f8b8860d1bbd654706ae21017bd8da694614c440/doc/languages-frameworks/neovim.section.md

    withPython3 = true;
    withNodeJs = true;
    withRuby = true;

    vimAlias = true;
    viAlias = true;

    configure = {
      customRC = neovimLuaRc;
    };
  };
in
(with pkgs-stable; [
  #################################################################################
  # Basic utilities
  #################################################################################

  # https://www.gnu.org/software/coreutils/manual/html_node/index.html
  # https://www.mankier.com/package/coreutils-common
  coreutils-full

  # https://uutils.github.io/coreutils/docs/
  # uutils-coreutils-noprefix

  killall

  # https://www.gnu.org/software/sed/
  # https://www.mankier.com/1/sed
  gnused

  # rm replacement
  # https://github.com/MilesCranmer/rip2
  rip2

  # https://github.com/eth-p/bat-extras/blob/master/doc/batwatch.md
  bat-extras.batwatch

  # https://github.com/eth-p/bat-extras/blob/master/doc/batpipe.md
  bat-extras.batpipe

  # https://mhost.pustina.de/docs/usage_examples
  mhost

  #################################################################################
  # View processes
  #################################################################################

  # https://htop.dev
  htop

  # https://github.com/dalance/procs#usage
  procs

  /*
    Others I tried and don't like so much
    https://clementtsang.github.io/bottom/nightly/usage/general-usage/
    https://github.com/aksakalli/gtop
    https://github.com/bvaisvil/zenith
    https://github.com/xxxserxxx/gotop
  */

  #################################################################################
  # Shells
  #################################################################################

  # https://fishshell.com/docs/current/interactive.html
  fish

  # https://xon.sh/tutorial.html
  # Examples of .xsh code: https://github.com/search?q=language%3AXonsh&type=code
  xonsh

  /*
    Aim to use:
    fish for interactive usage
    xonsh for scripting
  */

  #################################################################################
  # Shell history
  #################################################################################

  hstr
  hishtory
  atuin

  #################################################################################
  # Bash
  #################################################################################

  bats
  shfmt

  #################################################################################
  # Navigating directories
  #################################################################################

  zoxide

  #################################################################################
  # Viewing files and directories
  #################################################################################

  # https://github.com/eza-community/eza
  eza

  # https://dystroy.org/broot/
  broot

  # https://github.com/bootandy/dust
  dust

  # https://github.com/Byron/dua-cli/
  dua

  # https://yazi-rs.github.io/docs/quick-start
  yazi

  #################################################################################
  # Finding files
  #################################################################################

  # https://www.mankier.com/1/find
  # https://www.mankier.com/1/xargs
  findutils

  # https://github.com/sharkdp/fd
  fd

  # https://github.com/eth-p/bat-extras/blob/master/doc/batgrep.md
  bat-extras.batgrep

  # https://junegunn.github.io/fzf/
  fzf

  # https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md
  ripgrep

  # https://github.com/phiresky/ripgrep-all
  ripgrep-all

  # https://ugrep.com
  ugrep

  #################################################################################
  # Pagers
  #################################################################################

  # https://github.com/sharkdp/bat#how-to-use
  bat

  # https://github.com/dandavison/delta
  delta

  # https://github.com/lucc/nvimpager
  nvimpager

  # https://github.com/eth-p/bat-extras/blob/master/doc/prettybat.md
  bat-extras.prettybat

  # https://github.com/eth-p/bat-extras/blob/master/doc/batman.md
  bat-extras.batman

  #################################################################################
  # Git
  #################################################################################

  git
  git-lfs

  #################################################################################
  # Jujutsu
  #################################################################################

  jujutsu
  lazyjj

  #################################################################################
  # Diffs
  #################################################################################

  # https://www.gnu.org/software/diffutils/diffutils.html
  diffutils

  # https://difftastic.wilfred.me.uk
  difftastic

  #################################################################################
  # Tools for multiple languages
  #################################################################################

  # https://gcc.gnu.org
  gcc

  # https://www.gnu.org/software/make/
  gnumake

  # https://just.systems/man/en/
  just

  # https://cmake.org/cmake/help/latest/
  cmake

  # https://tree-sitter.github.io/tree-sitter/
  tree-sitter

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

  # https://mise.jdx.dev
  mise

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

  # https://github.com/FiloSottile/age
  age

  # https://getsops.io/docs/
  sops

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

  # https://github.com/tailscale/tailscale
  tailscale
])

++ (with pkgs-pinned-unstable; [
  unstableNeovim

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
