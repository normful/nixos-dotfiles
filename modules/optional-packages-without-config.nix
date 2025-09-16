{
  config,
  lib,
  pkgs-stable,
  pkgs-pinned-unstable,
  ...
}:
let
  optionals = lib.optionals;
  isDarwin = pkgs-pinned-unstable.stdenv.isDarwin;
in
{
  config = {
    environment.systemPackages =
      with pkgs-pinned-unstable;
      (optionals config.my.enableAiCodingAgents [
        opencode
      ])
      ++ (optionals config.my.enableLangTsJs [
        nodejs
        bun
        yarn
        deno
        nodePackages.prettier
        prettierd
        eslint_d
      ])
      ++ (optionals config.my.enableLangGo [
        go
        gopls
        gotools
        protoc-gen-go
        cobra-cli
        golangci-lint
      ])
      ++ (optionals config.my.enableLangRust [
        rustup
      ])
      ++ (optionals config.my.enableLangPython [
        uv
      ])
      ++ (optionals config.my.enableLangC [
        gcc
        gnumake
      ])
      ++ (optionals config.my.enableLangBash [
        bats
        shfmt
      ])
      ++ (optionals config.my.enableLangRuby [
        ruby
        rubyPackages.rubocop
        rubyPackages.pry
      ])
      ++ (optionals config.my.enableLangCss [
        stylelint
      ])
      ++ (optionals config.my.enableLangPhp [
        php
        php84Packages.composer
        php84Packages.php-cs-fixer
        php84Extensions.xdebug
        intelephense
      ])
      ++ (optionals config.my.enableLangNix [
        nixfmt-rfc-style
        nix-prefetch-github
      ])
      ++ (optionals config.my.enableLangGleam [
        gleam
      ])
      ++ (optionals config.my.enableLangErlang [
        beam.packages.erlang_28.erlang
        beam.packages.erlang_28.rebar3
      ])
      ++ (optionals config.my.enableLangUml [
        plantuml
      ])
      ++ (optionals config.my.enableLangTypst [
        typst
        tinymist
        typstwriter
      ])
      ++ (optionals config.my.enableDocker [
        docker
        docker-compose
        lazydocker
      ])
      ++ (optionals (config.my.enableDocker && isDarwin) [
        colima
      ])
      ++ (optionals config.my.enableLogTools [
        lnav
        hl-log-viewer
      ])
      ++ (optionals config.my.enableNetworkingTools [
        dogdns
        dnslookup
        mhost
        tcpdump
        xh
        grpcurl
        wget2
      ])
      ++ (optionals config.my.enableFileSyncTools [
        rsync
        lftp
      ])
      ++ (optionals config.my.enableBackupTools [
        restic
        rclone
        (callPackage ../packages/better-adb-sync { })
      ])
      ++ (optionals config.my.enablePdfTools [
        ghostscript
        qpdf
        diff-pdf
      ])
      ++ (optionals config.my.enableJujutsu [
        jujutsu
        lazyjj
      ])
      ++ (optionals config.my.enableJsonTools [
        jq
        jless
        fastgron
        jsonschema-cli
      ])
      ++ (optionals config.my.enableGitTools [
        git
        gh
        git-lfs
        opencommit
      ])
      ++ (optionals config.my.enableAudioVideoTools [
        ffmpeg
        vorbis-tools
        musikcube
      ])
      ++ (optionals config.my.enableImageTools [
        inkscape
        imagemagick
        pngcrush
      ])
      ++ (optionals config.my.enableScreenSharingTools [
        scrcpy
        remmina
      ]);
  };
}
