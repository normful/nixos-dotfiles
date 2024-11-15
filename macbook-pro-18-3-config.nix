{ config, pkgs, nixpkgs, ... }:

let
  myNeovim = pkgs.neovim.override {
    withPython3 = true;
    withNodeJs = true;
    withRuby = true;

    vimAlias = true;
    viAlias = true;

    configure = (import ./nix-nvim/nvim.nix { pkgs = pkgs; nixpkgs = nixpkgs; });
  };
in
{
  imports = [];

  system.stateVersion = 4;

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
      auto-optimise-store = true
      '';
    gc = {
      automatic = true;
      options = "--delete-older-than 600d";
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
    dns = [ "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001" ];
  };

  environment = {
    darwinConfig = "\$HOME/code/nixos-dotfiles/macbook-pro-18-3-config.nix";
    variables = {
      EDITOR = "nvim";
      GIT_EDITOR = "nvim";
      TERMINAL = "kitty";
    };
    shells = [ pkgs.fish ];
    systemPackages = with pkgs; [
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

      fish

      myNeovim
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

      cargo
      zola

      nodejs
      yarn
      nodePackages.prettier

      deno

      (python310.withPackages (pks: with pks; [
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
    ];
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
    '';
  };
}
