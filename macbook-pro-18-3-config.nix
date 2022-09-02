{ config, pkgs, nixpkgs, neovim-nightly-overlay, ... }:

let
  myNeovim = pkgs.neovim.override {
    withPython3 = true;
    withNodeJs = true;
    withRuby = true;

    vimAlias = true;
    viAlias = true;

    configure = (import ./nvim/nvim.nix { pkgs = pkgs; nixpkgs = nixpkgs; });
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
      options = "--delete-older-than 30d";
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
    overlays = [ neovim-nightly-overlay.overlay ];
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

      git
      delta

      curl
      wget

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
      rnix-lsp

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

      nodejs
      yarn
      nodePackages.prettier

      (python310.withPackages (pks: with pks; [
        black
        isort
        mypy
        pip
        pyflakes
        pylint
        pynvim
      ]))
      poetry
      nodePackages.pyright

      cargo

      inkscape
      imagemagick
      plantuml
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
        "com.apple.sound.beep.volume" = "0.000";
        AppleFontSmoothing = 1;
        AppleInterfaceStyle = "Dark";
        ApplePressAndHoldEnabled = false;
        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = 1;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        AppleShowScrollBars = "Automatic";
        AppleTemperatureUnit = "Celsius";

        # Use https://mac-key-repeat.zaymon.dev to preview these settings
        # See https://apple.stackexchange.com/a/288764 for steps
        InitialKeyRepeat = 35;
        KeyRepeat = 3;
      };

      finder = {
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = true;
        _FXShowPosixPathInTitle = true;
      };
    };

    activationScripts.postUserActivation.text = ''
      echo "Show all files in Finder"
      defaults write com.apple.Finder AppleShowAllFiles -bool YES

      echo "Avoid creating .DS_Store files on network volumes"
      defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

      echo "Disable the warning before emptying the Trash"
      defaults write com.apple.finder WarnOnEmptyTrash -bool false

      echo "Require password immediately after sleep or screen saver begins"
      defaults write com.apple.screensaver askForPassword -int 1
      defaults write com.apple.screensaver askForPasswordDelay -int 0

      defaults write -g ApplePressAndHoldEnabled -bool false

    '';
  };
}
