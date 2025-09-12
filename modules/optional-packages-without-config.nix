{
  config,
  lib,
  pkgs-stable,
  pkgs-pinned-unstable,
  ...
}:
let
  optionals = lib.optionals;
in
{
  config = {
    environment.systemPackages =
      with pkgs-pinned-unstable;
      (optionals config.my.enableLangTsJs [
        nodejs
        bun
        yarn
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
        poetry
        python3Minimal
        python313Packages.numpy
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
        php84Extensions.xdebug
        php84Packages.php-cs-fixer
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
        colima
        docker
        docker-compose
      ])
      ++ (optionals config.my.enableNetworkingTools [
        dogdns
        dnslookup
        mhost
        tcpdump
        curl
        wget2
        xh
        grpcurl
      ])
      ++ (optionals config.my.enableFileSyncTools [
        rsync
        rclone
        lftp
        better-adb-sync
        restic
      ])
      ++ (optionals config.my.enablePdfTools [
        ghostscript
        qpdf
        diff-pdf
      ])
      ++ (optionals config.my.enableLogTools [
        lnav
        hl-log-viewer
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
      ]);
  };
}
