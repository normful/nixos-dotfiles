{
  config,
  lib,
  pkgs-pinned-unstable,
  ...
}:
let
  optionals = lib.optionals;
  isDarwin = pkgs-pinned-unstable.stdenv.isDarwin;
  isX86_64Linux = pkgs-pinned-unstable.stdenv.isLinux && pkgs-pinned-unstable.stdenv.isx86_64;
in
{
  config = {
    environment.systemPackages =
      with pkgs-pinned-unstable;
      (optionals config.my.enableAiCodingAgents [
        opencode
        (callPackage ../packages/grok-cli { })
      ])
      ++ (optionals config.my.enableMultiLangTools [
        just
        cloc
        cmake
        just
        modd
        efm-langserver
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
        parallel
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
        php84Extensions.xdebug
        php83Packages.php-cs-fixer # Temporarily use 8.3 one because 8.4 Nix package is broken
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
      ++ (optionals config.my.enableDiagramTools [
        temurin-jre-bin-24
        plantuml
        graphviz
      ])
      ++ (optionals config.my.enableLangTypst [
        typst
        tinymist
        typstwriter
      ])
      ++ (optionals config.my.enableMarkdownCliTools [
        glow
        mdcat
        doctoc
        mdp
        panvimdoc
        mermaid-cli
        gtree
        mdq
        codebraid
      ])
      ++ (optionals config.my.enableMarkdownGuiTools [
        folio
      ])
      ++ (optionals (config.my.enableMarkdownGuiTools && isX86_64Linux) [
        percollate
        typora
        apostrophe
        zettlr
        notable
      ])
      ++ (optionals config.my.enableConfigLangsTools [
        otree
        jless

        jq
        yq-go
        go-toml
        dasel
        taplo

        fastgron
        jsonschema-cli

        cue
      ])
      ++ (optionals config.my.enableDocker [
        docker
        docker-buildx
        docker-compose
        lazydocker

        devpod
        devpod-desktop
      ])
      ++ (optionals (config.my.enableDocker && isDarwin) [
        colima
      ])
      ++ (optionals config.my.enableKubernetes [
        minikube
        kind
        k3d

        kubernetes-helm
        helmfile
        kube-linter

        kubectl
        k9s
        kubetail

        kubescape
        kubesec
        kubeshark

        timoni

        werf
        nelm

        devspace
      ])
      ++ (optionals config.my.enableSqlDbTools [
        sql-studio
        dbeaver-bin
      ])
      ++ (optionals config.my.enableMysqlMariaDbTools [
        mycli
      ])
      ++ (optionals config.my.enablePostgresqlDbTools [
        pgcli
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
      ++ (optionals config.my.enableWindowsTools [
        dos2unix
      ])
      ++ (optionals config.my.enableJujutsu [
        jujutsu
        lazyjj
      ])
      ++ (optionals config.my.enableGitTools [
        git
        git-lfs
        git-filter-repo
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
