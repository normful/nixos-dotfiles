{
  config,
  lib,
  pkgs-pinned-unstable,
  ...
}:
let
  optionals = lib.optionals;
  isDarwin = pkgs-pinned-unstable.stdenv.isDarwin;
  isLinux = pkgs-pinned-unstable.stdenv.isLinux;
  isX86_64Linux = pkgs-pinned-unstable.stdenv.isLinux && pkgs-pinned-unstable.stdenv.isx86_64;
  phpEnv = (
    pkgs-pinned-unstable.php84.buildEnv {
      extensions = (
        { enabled, all }:
        enabled
        ++ (with all; [
          curl
          mbstring
          mysqli
          pdo
          pdo_mysql
          # pcov
          xdebug
          zip
        ])
      );

      # Also read https://thephp.cc/articles/pcov-or-xdebug
      # Only enable either pcov or xdebug. When pcov is enabled by configuration pcov.enabled=1: interoperability with Xdebug is not possible
      extraConfig = ''
        display_errors = On
        display_startup_errors = On
        error_reporting = E_ALL
        memory_limit = 2G
        opcache.interned_strings_buffer = 20
        opcache.memory_consumption = 256M

        xdebug.mode = coverage
        pcov.enabled = Off
      '';
    }
  );
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
        hyperfine
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
        lefthook
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
        phpEnv
        phpEnv.packages.composer
        phpEnv.packages.php-cs-fixer
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
        presenterm
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
      ++ (optionals config.my.enablePkmTools [
        zk
      ])
      ++ (optionals config.my.enableConfigLangsTools [
        otree
        jless

        jq
        yq-go
        yamllint
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
      ])
      ++ (optionals (config.my.enableDocker && isDarwin) [
        colima
      ])
      ++ (optionals (config.my.enableDocker && isLinux) [
        devpod-desktop
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
        zdns
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
        imagemagick
        pngcrush
      ])
      ++ (optionals (config.my.enableImageTools && isLinux) [
        darktable
      ])
      ++ (optionals (config.my.enableImageTools && isDarwin) [
        pngpaste
      ])
      ++ (optionals config.my.enableColorTools [
        pastel
      ])
      ++ (optionals config.my.enableScreenSharingTools [
        scrcpy
        remmina
      ]);

    fonts.packages =
      with pkgs-pinned-unstable;
      (optionals config.my.enableFonts [
        annotation-mono
        atkinson-hyperlegible-next
        hasklig
        hubot-sans
        mona-sans
        nerd-fonts._0xproto
        nerd-fonts.inconsolata
        nerd-fonts.monaspace
        nerd-fonts.recursive-mono
        pecita
        recursive
        tt2020
      ])
      ++ (optionals config.my.enableJapaneseFonts [
        biz-ud-gothic
        dotcolon-fonts
        explex-nf
        hachimarupop
        moralerspace-hwjpdoc
        noto-fonts-cjk-sans
      ]);
  };
}
