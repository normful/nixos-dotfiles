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
    pkgs-pinned-unstable.php85.buildEnv {
      extensions = (
        { enabled, all }:
        enabled
        ++ (with all; [
          curl
          mbstring
          mysqli
          pdo
          pdo_mysql
          zip

          # Only enable either pcov or xdebug.
          # pcov
          xdebug
        ])
      );

      # When pcov.enabled = On, interoperability with Xdebug is NOT possible
      # More info https://thephp.cc/articles/pcov-or-xdebug
      extraConfig = ''
        display_errors = On
        display_startup_errors = On
        error_reporting = E_ALL
        memory_limit = 2G
        opcache.interned_strings_buffer = 20
        opcache.memory_consumption = 256M

        pcov.enabled = Off
        xdebug.mode = coverage
      '';
    }
  );
in
{
  config = {
    environment.systemPackages =
      with pkgs-pinned-unstable;
      (optionals config.my.enableMultiLangTools [
        mise
        cloc
        just
        cmake
        modd
        efm-langserver
        hyperfine
        unixtools.watch
        goreleaser
        grex
      ])
      ++ (optionals config.my.enableLangTsJs [
        nodejs
        yarn
        bun
        pnpm
        deno

        typescript-go
        typescript-language-server

        prettierd
        eslint_d
        oxfmt
        oxlint
        tsgolint
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
        python314Packages.python-lsp-server
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
        nixfmt
        nix-prefetch-github
        nix-search-cli
      ])
      ++ (optionals config.my.enableLangGleam [
        gleam
      ])
      ++ (optionals config.my.enableLangErlang [
        beam.packages.erlang_28.erlang
        beam.packages.erlang_28.rebar3
      ])
      ++ (optionals config.my.enableDiagramTools [
        mermaid-cli
        plantuml
        d2
        gnuplot
        graphviz
        gnuplot
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
        gtree
        mdq
        codebraid
        presenterm
        pandoc
        rumdl
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

        # Not using source-meta-json-schema and instead preferring jsonschema-cli for now, because jsonschema-cli looks faster
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

        nelm

        devspace
      ])
      ++ (optionals config.my.enableSqlDbTools [
        duckdb
        sql-studio
        dbeaver-bin
      ])
      /*
        ++ (optionals config.my.enableMysqlMariaDbTools [
          mycli
        ])
      */
      ++ (optionals config.my.enablePostgresqlDbTools [
        pgcli
      ])
      ++ (optionals config.my.enableLogTools [
        lnav
        hl-log-viewer
      ])
      ++ (optionals config.my.enableSecretsTools [
        sops
        age
        betterleaks
        yubikey-manager
      ])
      ++ (optionals config.my.enableNetworkingTools [
        doggo
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
        git-cliff
        opencommit
      ])
      ++ (optionals config.my.enableGitHookTools [
        lefthook
        prek
      ])
      ++ (optionals config.my.enableAudioVideoTools [
        ffmpeg
        vorbis-tools
        musikcube
        lowfi
        asciinema
      ])
      ++ (optionals config.my.enableImageTools [
        imagemagick
        pngcrush
        exiftool
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
        hubot-sans
        mona-sans
        nerd-fonts._0xproto
        nerd-fonts.inconsolata
        nerd-fonts.monaspace
        nerd-fonts.recursive-mono

        # Fonts that looked nice, but did not end up using
        # annotation-mono
        # atkinson-hyperlegible-next
        # hasklig
        # pecita
        # recursive
        # tt2020
      ])
      ++ (optionals config.my.enableJapaneseFonts [
        noto-fonts-cjk-sans
        moralerspace-hwjpdoc

        # Fonts that looked nice, but did not end up using
        # biz-ud-gothic
        # dotcolon-fonts
        # explex-nf
        # hachimarupop
      ]);
  };
}
