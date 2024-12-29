{ nixpkgs-stable, nixpkgs-pinned-unstable, pkgs-stable, pkgs-pinned-unstable, ... }:

let
  myNeovim = pkgs-pinned-unstable.neovim.override {
    withPython3 = true;
    withNodeJs = true;
    withRuby = true;

    vimAlias = true;
    viAlias = true;

    configure = (import ./nix-nvim/nvim.nix { pkgs = pkgs-pinned-unstable; nixpkgs = nixpkgs-pinned-unstable; });
  };
in
{
  imports = [];

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
    overlays = [];
  };

  networking = {
    knownNetworkServices = [ "Wi-Fi" "Thunderbolt Bridge" ];
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
      TERMINAL = "kitty";
    };
    shells = [ pkgs-stable.fish ];
    systemPackages =
      (with pkgs-stable; [
        coreutils-full
        findutils
        gnused
        lsd
        bat
        openssl
        tcpdump
        ntfs3g

        stow
        gnumake
        cmake
        killall
        ghostscript

        git
        git-lfs
        delta

        curl
        wget
        rsync

        restic
        rclone

        htop
        tree

        bats

        fish

        nodePackages.neovim
        tree-sitter
        ctags
        efm-langserver
        (lua5_1.withPackages (pks: with pks; [
          luarocks
        ]))
        stylua

        hstr
        zoxide
        fzf

        fd
        ripgrep
        ripgrep-all
        ugrep

        jq

        gcc

        go
        gopls
        gotools
        protoc-gen-go
        cobra-cli

        cargo
        zola

        nodejs
        yarn
        nodePackages.prettier

        (python312.withPackages (pks: with pks; [
          black
          isort
          mypy
          pip
          pipx
          pyflakes
          pylint
          pynvim
        ]))
        poetry

        inkscape
        imagemagick
        pngcrush
        plantuml

        ffmpeg
        vorbis-tools

        scrcpy

        texliveSmall
        pandoc
        qpdf
      ])

      ++
      (with pkgs-pinned-unstable; [
        deno
        myNeovim
        gleam
        beam.packages.erlang_27.erlang
        beam.packages.erlang_27.rebar3
      ]);
  };

  programs = {
    fish = {
      enable = true;
    };
  };

  services = {
    nix-daemon = {
      enable = true;
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

    activationScripts.postUserActivation.text = ''
      defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
      defaults write com.apple.finder WarnOnEmptyTrash -bool false
      defaults write com.apple.screensaver askForPassword -int 1
      defaults write com.apple.screensaver askForPasswordDelay -int 0
      defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerContentType=public.plain-text;LSHandlerRoleAll=com.neovide.neovide;}'
    '';
  };
}
