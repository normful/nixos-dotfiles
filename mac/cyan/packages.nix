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
  # Git
  #################################################################################

  git
  gh


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  #~~~~TODO~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  #~~~~~Below this line, most packages need to be placed into `modules`~~~~~~~~~~~~
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  #################################################################################
  # Tools for multiple languages
  #################################################################################

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
  # Regular expressions
  #################################################################################

  # https://pemistahl.github.io/grex-js/
  # https://github.com/pemistahl/grex?tab=readme-ov-file#51-the-command-line-tool
  grex


  #################################################################################
  # TOML
  #################################################################################

  # https://taplo.tamasfe.dev/cli/introduction.html
  taplo


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

  # https://pandoc.org/MANUAL.html
  pandoc





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

  # https://www.getzola.org/documentation/getting-started/cli-usage/
  zola

  # https://github.com/sharkdp/hyperfine#usage
  hyperfine

  # https://docs.cointop.sh
  cointop

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
