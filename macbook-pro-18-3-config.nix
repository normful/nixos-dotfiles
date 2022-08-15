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

      htop
      tree

      kitty
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

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      function cat
          type -fq bat
          and command bat $argv
          or  command cat $argv
      end

      abbr --add l 'ls -lhAtr --color=always'

      abbr --add h history
      abbr --add d dirh
      abbr --add nd nextd
      abbr --add pd prevd

      abbr --add c clear
      abbr --add q exit
      abbr --add t 'tree -N -ashFC -I ".git|node_modules"'

      abbr --add utc 'date -u'

      abbr --add ag rg

      abbr --add g git
      abbr --add qg git
      abbr --add gl 'git l'
      abbr --add gs 'git s'

      abbr --add v nvim
      abbr --add vi nvim
      abbr --add nv nvim
      abbr --add vim nvim

      abbr --add ea "nvim $HOME/code/nixos-dotfiles/macbook-pro-18-3-config.nix"
      abbr --add en "nvim $HOME/code/nixos-dotfiles/macbook-pro-18-3-config.nix"

      abbr --add ek "nvim $HOME/code/nixos-dotfiles/kitty/.config/kitty/kitty.conf"
      abbr --add ef "nvim $HOME/code/nixos-dotfiles/fish/.config/fish/config.fish"
      abbr --add ev "nvim $HOME/code/nixos-dotfiles/nvim/nvim.nix"
      abbr --add eg "nvim $HOME/code/nixos-dotfiles/git/.gitconfig"

      alias mm="cd ~/code/nixos-dotfiles && make mac"
    '';
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
        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = 1;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        AppleShowScrollBars = "Automatic";
        AppleTemperatureUnit = "Celsius";
        InitialKeyRepeat = 10;
        KeyRepeat = 1;
      };

      finder = {
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = true;
        _FXShowPosixPathInTitle = true;
      };
    };

    activationScripts.postUserActivation.text = ''
      defaults write com.apple.Finder AppleShowAllFiles -bool YES
    '';
  };
}
