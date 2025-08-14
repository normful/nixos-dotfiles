{
  nixpkgs-stable,
  nixpkgs-pinned-unstable,
  pkgs-stable,
  pkgs-pinned-unstable,
  ...
}:

let
  unstableNeovim = pkgs-pinned-unstable.neovim.override {
    # https://github.com/NixOS/nixpkgs/blob/f8b8860d1bbd654706ae21017bd8da694614c440/doc/languages-frameworks/neovim.section.md

    withPython3 = true;
    withNodeJs = true;
    withRuby = true;

    vimAlias = true;
    viAlias = true;

    configure = {
      customRC = pkgs-pinned-unstable.callPackage ./nix-nvim/customRC.vim.nix { };
    };
  };
in
{
  imports = [ ];

  system.stateVersion = 4;

  nix = {
    package = pkgs-stable.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
      keep-failed = false
      keep-going = true
      auto-optimise-store = false
    '';
    gc = {
      automatic = true;
      options = "--delete-older-than 600d";
    };
    optimise = {
      automatic = true;
    };
  };

  nixpkgs = {
    # The configuration of the Nix Packages collection. (For details, see the Nixpkgs documentation.)
    # This allows you to set package configuration options, and to override packages globally through the packageOverrides option.
    config = {
      allowUnfree = true;
    };

    # List of overlays to use with the Nix Packages collection.
    # This overrides packages globally.
    overlays = [ ];
  };

  networking = {
    knownNetworkServices = [
      "Wi-Fi"
      "Thunderbolt Bridge"
    ];
    dns = [
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
  };

  environment = {
    darwinConfig = "\$HOME/code/nixos-dotfiles/macbook-pro-18-3-config.nix";
    variables = {
      EDITOR = "nvim";
      GIT_EDITOR = "nvim";
    };
    shells = [ pkgs-stable.fish ];
    systemPackages =
      (with pkgs-stable; [
        #################################################################################
        # Basic utilities
        #################################################################################

        # https://www.gnu.org/software/coreutils/manual/html_node/index.html
        # https://www.mankier.com/package/coreutils-common
        # coreutils-full

        # https://uutils.github.io/coreutils/docs/
        uutils-coreutils-noprefix

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

        #################################################################################
        # View processes
        #################################################################################

        # https://htop.dev
        htop

        # https://github.com/dalance/procs#usage
        procs

        # Others I tried and don't like so much
        # https://clementtsang.github.io/bottom/nightly/usage/general-usage/
        # https://github.com/aksakalli/gtop
        # https://github.com/bvaisvil/zenith
        # https://github.com/xxxserxxx/gotop

        #################################################################################
        # Shells
        #################################################################################

        fish

        xonsh

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
        nix-prefetch-github

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

        #################################################################################
        # Golang
        #################################################################################

        go
        gopls
        gotools
        protoc-gen-go
        cobra-cli

        #################################################################################
        # Rust
        #################################################################################

        rustup

        #################################################################################
        # Node.js
        #################################################################################

        nodejs
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
            black
            isort
            mypy
            pip
            pipx
            pyflakes
            pylint
            pynvim
          ]
        ))
        poetry

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
        intelephense
        php84Extensions.xdebug

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
        # Audio and video
        #################################################################################

        # https://www.ffmpeg.org/documentation.html
        ffmpeg

        # https://xiph.org/vorbis/
        vorbis-tools

        #################################################################################
        # Typesetting
        #################################################################################

        # https://www.tug.org/texlive/doc.html
        texliveSmall

        # https://github.com/typst/typst
        typst

        # https://github.com/Myriad-Dreamin/tinymist
        tinymist

        # https://github.com/Bzero/typstwriter
        typstwriter

        #################################################################################
        # PDF
        #################################################################################

        # https://qpdf.readthedocs.io/en/stable/
        qpdf

        # https://vslavik.github.io/diff-pdf/
        diff-pdf

        # https://ghostscript.readthedocs.io/en/latest/Use.html
        ghostscript

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

        #################################################################################
        # Others
        #################################################################################

        # https://www.gnu.org/software/stow/
        stow

        # https://docs.openssl.org/master/man1/openssl/
        openssl

        # https://restic.readthedocs.io/en/stable/
        restic

        # https://pandoc.org/MANUAL.html
        pandoc

        # https://github.com/Genymobile/scrcpy
        scrcpy

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

        # https://github.com/sharkdp/pastel?tab=readme-ov-file#use-cases-and-demo
        pastel

        # https://wiki.archlinux.org/title/Remmina
        remmina

        # https://infisical.com/docs/cli/usage
        infisical

        # https://graphviz.org
        graphviz
      ])

      ++ (with pkgs-pinned-unstable; [
        unstableNeovim

        # https://docs.helix-editor.com/usage.html
        # https://github.com/helix-editor/helix/wiki/Migrating-from-Vim
        helix

        # https://docs.deno.com
        deno

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
        # AI Coding Agents
        #################################################################################

        # https://docs.anthropic.com/en/docs/claude-code/overview
        claude-code

        # https://github.com/google-gemini/gemini-cli#-documentation
        gemini-cli

        # https://github.com/charmbracelet/crush
        crush
      ]);
  };

  programs = {
    fish = {
      enable = true;
    };
  };

  services = {
    nix-daemon = {
      logFile = "/var/log/nix-daemon.log";
    };
  };

  system = {
    defaults = {
      NSGlobalDomain = {
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.feedback" = 0;
        "com.apple.sound.beep.volume" = 0.000;
        AppleFontSmoothing = 1;
        AppleInterfaceStyle = "Dark";
        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = 1;
        ApplePressAndHoldEnabled = false;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        AppleShowScrollBars = "Automatic";
        AppleTemperatureUnit = "Celsius";

        # You can use https://mac-key-repeat.zaymon.dev to preview these settings without a restart
        InitialKeyRepeat = 8;
        KeyRepeat = 2;
      };

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        FXEnableExtensionChangeWarning = true;
        _FXShowPosixPathInTitle = true;
      };
    };

    activationScripts = {
      setAppleDefaults.text = ''
        defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
        defaults write com.apple.finder WarnOnEmptyTrash -bool false
        defaults write com.apple.screensaver askForPassword -int 1
        defaults write com.apple.screensaver askForPasswordDelay -int 0
        defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerContentType=public.plain-text;LSHandlerRoleAll=com.neovide.neovide;}'
      '';
    };

    primaryUser = "norman";
  };
}
