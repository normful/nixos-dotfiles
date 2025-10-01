{
  pkgs-stable,
  pkgs-pinned-unstable,
  config,
  ...
}:
{
  imports = [
    ../../modules/overall-options.nix
    ../../modules/interactive-cli.nix
    ../../modules/locale.nix
    ../../modules/neovim.nix
    ../../modules/optional-packages-without-config.nix
  ];

  config = {
    my.user.name = "norman";

    my.enableInteractiveCli = true;
    my.enableFullNeovim = true;

    my.enableAiCodingAgents = true;
    my.enableMultiLangTools = true;
    my.enableLangTsJs = true;
    my.enableLangGo = true;
    my.enableLangRust = true;
    my.enableLangPython = true;
    my.enableLangBash = true;
    my.enableLangRuby = true;
    my.enableLangCss = true;
    my.enableLangPhp = true;
    my.enableLangLua = true;
    my.enableLangNix = true;
    my.enableLangGleam = true;
    my.enableLangErlang = true;
    my.enableLangTypst = true;
    my.enableMarkdownCliTools = true;
    my.enableMarkdownGuiTools = true;
    my.enableConfigLangsTools = true;

    my.enableDocker = true;
    my.enableKubernetes = true;
    my.enableSqlDbTools = true;
    my.enableMysqlMariaDbTools = true;
    my.enableNetworkingTools = true;
    my.enableFileSyncTools = true;
    my.enablePdfTools = true;
    my.enableWindowsTools = true;
    my.enableLogTools = true;
    my.enableJujutsu = true;
    my.enableGitTools = true;
    my.enableDiagramTools = true;
    my.enableAudioVideoTools = true;
    my.enableImageTools = true;
    my.enableScreenSharingTools = true;

    system.stateVersion = 4;

    nix = {
      package = pkgs-stable.nixVersions.latest;
      settings = {
        max-jobs = 10; # Apple M1 Pro has 10 CPU cores (8 performance + 2 efficiency)
      };
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
        options = "--delete-older-than 30d";
      };
      optimise = {
        automatic = true;
      };
    };

    nixpkgs = {
      config = {
        allowUnfree = true;
      };
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
      systemPackages = import ./packages.nix { inherit pkgs-stable pkgs-pinned-unstable; };
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
          AppleWindowTabbingMode = "always";

          # You can use https://mac-key-repeat.zaymon.dev to preview these settings without a restart
          InitialKeyRepeat = 8;
          KeyRepeat = 2;
        };

        dock = {
          appswitcher-all-displays = true;
          autohide = true;
          autohide-delay = 0.0;
          autohide-time-modifier = 0.5;
          expose-animation-duration = 0.1;
          mineffect = "scale";
          minimize-to-application = true;
          mouse-over-hilite-stack = false;
          mru-spaces = false;
          persistent-apps = [
            "/Applications/WezTerm.app"
            "/Applications/Warp.app"
            "/Applications/Ghostty.app"
            "/Applications/Vivaldi.app"
            "/Applications/Orion.app"
            "/Applications/Notion.app"
            "/Applications/Jan.app"
            "/Applications/superwhisper.app"
            "/Applications/KeePassXC.app"
            "/Applications/LINE.app"
            "/Applications/Spark.app"
            "/Applications/Insta360 Studio.app"
            "/Applications/FileZilla.app"
            "/Applications/QuickShade.app"
            "/System/Applications/System Settings.app"
          ];
          show-process-indicators = true;
          show-recents = false;
          tilesize = 48;
          wvous-br-corner = 13; # Hot corner action for bottom right corner: Lock Screen
        };

        finder = {
          AppleShowAllExtensions = true;
          AppleShowAllFiles = true;
          CreateDesktop = false;
          FXEnableExtensionChangeWarning = true;
          _FXShowPosixPathInTitle = true;
        };

        spaces = {
          spans-displays = false;
        };

        WindowManager = {
          EnableStandardClickToShowDesktop = false;
          EnableTiledWindowMargins = false;
          EnableTopTilingByEdgeDrag = false;
          GloballyEnabled = false;
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

      primaryUser = config.my.user.name;
    };
  };
}
