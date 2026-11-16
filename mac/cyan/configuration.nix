{
  pkgs,
  pkgs-stable,
  pkgs-pinned-unstable,
  config,
  inputs,
  ...
}: {
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
    my.enablePkmTools = true;
    my.enableConfigLangsTools = true;

    my.enableDocker = true;
    my.enableKubernetes = false;
    my.enableSqlDbTools = true;
    my.enableMysqlMariaDbTools = true;
    my.enableNetworkingTools = true;
    my.enableFileSyncTools = true;
    my.enableBackupTools = true;
    my.enablePdfTools = true;
    my.enableWindowsTools = true;
    my.enableLogTools = true;
    my.enableSecretsTools = true;
    my.enableJujutsu = true;
    my.enableGitTools = true;
    my.enableGitHookTools = true;
    my.enableDiagramTools = true;
    my.enableAudioVideoTools = true;
    my.enableImageTools = true;
    my.enableColorTools = true;
    my.enableScreenSharingTools = false;
    my.enableFonts = true;
    my.enableJapaneseFonts = true;

    environment.systemPackages =
      [
      ]
      ++ (with pkgs-pinned-unstable; [
        tailscale
        keepassxc
        gh # Log into this one manually

        # Packages I'm only installing on this computer for now
        terminal-notifier
        hk
        atuin
        sqlite
        himalaya
        mdwatch

        # crystal
        jre25_minimal

        # adoc
        asciidoctor-with-extensions
        kramdown-asciidoc

        # TeX Live Medium + extra CJK/XeTeX packages
        (texliveMedium.withPackages (
          ps:
            with ps; [
              xecjk
              fontspec
            ]
        ))
        ansible
        fswatch

        git-credential-oauth
        sesh

        # ────────────────────────────────────────────────────────────────────────
        # TODO: Replace many (all?) with https://github.com/berberman/nvfetcher
        # Examples of other people also using nvfetcher:
        # - https://github.com/search?q=path%3A_sources%2Fgenerated.nix&type=code
        # - https://github.com/search?q=path%3AREADME.md+nvfetcher&type=code
        # ────────────────────────────────────────────────────────────────────────

        # ── keepers ──

        (callPackage ../../packages/agent-browser {})
        (callPackage ../../packages/lean-ctx {})
        (callPackage ../../packages/tpluck {})
        (callPackage ../../packages/duvis {})
        (callPackage ../../packages/git-surgeon {})
        (callPackage ../../packages/aven {})
        (callPackage ../../packages/omp {})
        (callPackage ../../packages/opencode {})
        # swival is a uv-locked virtualenv (uv2nix), not a plain buildPythonApplication:
        # see packages/swival/default.nix. The flake inputs are passed in because
        # callPackage here only carries nixpkgs attrs.
        (callPackage ../../packages/swival {
          inherit (inputs) uv2nix pyproject-nix pyproject-build-systems;
        })

        # ── low interest ──

        # Multi-format document parser (PDF, DOCX, XLSX, HTML, images,
        # audio). Removed entirely: pulled ~2.0 GB exclusive (torch,
        # torchvision, gfortran, scipy, onnxruntime) for a CLI rarely used.

        # Open-source Agent OS. Deploy, manage, orchestrate AI agents from
        # terminal. 40 channels, 60 skills, 50+ models. Autonomous 24/7.
        (callPackage ../../packages/openfang {})

        # Multi-agent orchestrator. Runs a crew of CLI coding agents
        # (Claude Code, Codex, Gemini CLI, 40+) with HMAC audit chain.
        (callPackage ../../packages/bernstein {})

        # ────────────────────────────────────────────────────────────────────────
        # Packages I've used before but don't need now
        # ────────────────────────────────────────────────────────────────────────

        # (callPackage ../../packages/dcg {})

        # infisical
        # direnv
        # dolt
        # tuios
        # zola
        # repomix
        # sqlite-web
        # jcode
        # git-ai
        # arxiv-cli
        # impeccable

        # ────────────────────────────────────────────────────────────────────────
        # Example packages and overlaid packages
        # ────────────────────────────────────────────────────────────────────────

        hello-wrapped # from overlays/hello-wrapped-config — hello with default --greeting flag
        figlet-patched # from overlays/figlet-patched — figlet defaulting to smslant font
        (callPackage ../../packages/cowsay {}) # from packages/cowsay — cowsay pinned to v3.8.4
      ])
      ++ (with inputs.nix-casks.packages.${pkgs.stdenv.hostPlatform.system}; [
        flux
        keka
        key-codes
        mp3gain-express
        neovide

        ### Some of these are gigantic and slow down system rebuild, so I'm purposely just installing them imperatively, outside of Nix
        # anki
        # brave-browser
        # cursor
        # discord
        # docker
        # firefox_nightly
        # inkscape
        # iptvnator
        # libreoffice
        # notion-calendar
        # orion
        # rustrover
        # slack
        # superwhisper
        # tor-browser
        # tunnelblick
        # visual-studio-code_insiders
        # vlc
        # zed
      ])
      ++ (with inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}; [
        herdr
      ])
      ++ (with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
        # AI Coding Agents
        # jules

        # Workflow & Project Management
        # beads-rust
        # beads-viewer
        # openspec # Small
        # cc-sdd # Large
        # spec-kit # Large
        # workmux

        # Others
        # tuicr
        # rtk
        # ck
        # gno
        # qmd
        # showboat
      ]);

    system.defaults.dock.persistent-apps = [
      # Terminals
      "/Applications/Ghostty.app"
      # "/Applications/kitty.app"
      # "/Applications/WezTerm.app"

      # Browsers
      "/Applications/Vivaldi.app"
      "/Applications/Zen.app"

      # Notes
      "/Applications/Notion.app"
      "/Applications/Obsidian.app"

      # Others
      "/Applications/MacParakeet.app"
      "/System/Applications/Calendar.app"
      "/Applications/Nix Apps/KeePassXC.app"
      "/Applications/LINE.app"
      "/Applications/Spark.app"
      "/Applications/Discord.app"
      "/Applications/OptiCull.app"
      "/Applications/darktable.app"
      "/Applications/QuickShade.app"
      "/System/Applications/System Settings.app"

      # "/Applications/FileZilla.app"
      # "/Applications/Insta360 Studio.app"
    ];

    system.defaults.dock.persistent-others = [
      "/Users/norman/code/CurrentlyReading-general"
      "/Users/norman/code/CurrentlyReading-japanese"
    ];

    system.stateVersion = 4;

    nix = {
      package = pkgs-stable.nixVersions.latest;
      settings = {
        max-jobs = 10; # Apple M1 Pro has 10 CPU cores (8 performance + 2 efficiency)
      };
      extraOptions = ''
        experimental-features = nix-command flakes
        keep-outputs = false
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
      variables = {
        EDITOR = "nvim";
        GIT_EDITOR = "nvim";
      };
      shells = [pkgs-pinned-unstable.fish];
    };

    programs = {
      fish = {
        enable = true;
        # Use the unstable pin so fish does not drag a second Python (3.13)
        # into the closure; 2605's fish is built against python313Packages.
        package = pkgs-pinned-unstable.fish;
      };

      # Also see:
      # https://github.com/nix-darwin/nix-darwin/blob/master/modules/programs/tmux.nix
      # https://github.com/ScopeCreep-zip/kalilix/blob/e526cd72ef2686143ae83460d380aa04dacede34/modules/programs/tmux/config.nix
      tmux = {
        enable = true;
        extraConfig = ''
          # Load user config
          if-shell '[ -f ~/.config/tmux/tmux.conf ]' 'source-file ~/.config/tmux/tmux.conf'
        '';
      };
    };

    services = {
      nix-daemon = {
        logFile = "/var/log/nix-daemon.log";
      };
    };

    system = {
      defaults = {
        loginwindow.GuestEnabled = false;

        CustomUserPreferences = {
          "com.apple.finder" = {
            AppleShowAllExtensions = true;
            DisableAllAnimations = true;
            FXDefaultSearchScope = "SCcf"; # When searching, search the current folder by default
            FXEnableExtensionChangeWarning = false;
            NewWindowTargetPath = "file:///Users/${config.my.user.name}/Downloads/";
            ShowExternalHardDrivesOnDesktop = false;
            ShowHardDrivesOnDesktop = false;
            ShowMountedServersOnDesktop = false;
            ShowRecentTags = false;
            ShowRemovableMediaOnDesktop = false;
            ShowStatusBar = true;
            ShowPathbar = false;
            ShowTabView = false;
            WarnOnEmptyTrash = false;
            _FXSortFoldersFirst = true;
          };
          "com.apple.desktopservices" = {
            # Avoid creating .DS_Store files on network or USB volumes
            DSDontWriteNetworkStores = true;
            DSDontWriteUSBStores = true;
          };
          "com.apple.CloudSubscriptionFeatures.optIn" = {
            "545129924" = false;
            "8187947588" = false;
          };
          "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
          "com.apple.assistant.support"."Assistant Enabled" = false;
          "com.apple.Siri".StatusMenuVisible = false;
          "com.apple.Siri".VoiceTriggerUserEnabled = false;
          "com.apple.suggestions".AppCanBeSuggested = false;
          "com.apple.suggestions".CloudKitSyncDisabled = true;
          "com.apple.suggestions".ContactsDisabled = true;
          "com.apple.suggestions".EventsDisabled = true;
          "com.apple.suggestions".IntentsDisabled = true;
          "com.apple.suggestions".LocationsDisabled = true;
          "com.apple.suggestions".SiriDisabledOnLockscreen = true;
          "com.apple.suggestions".UniversalLinksDisabled = true;
          "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
          "com.apple.ImageCapture".disableHotPlug = true;
          "com.apple.CrashReporter".DialogType = "none";
        };

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
          launchanim = false;
          mineffect = null;
          minimize-to-application = true;
          mouse-over-hilite-stack = false;
          mru-spaces = false;
          orientation = "right";
          show-process-indicators = true;
          show-recents = false;
          static-only = false;
          tilesize = 48;
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
          EnableTiledWindowMargins = true;
          EnableTopTilingByEdgeDrag = true;
          EnableTilingOptionAccelerator = true;
          GloballyEnabled = false;
          StandardHideDesktopIcons = true;
          StandardHideWidgets = true;
        };
      };

      activationScripts = {
        # Apply macOS user defaults that cannot be set via nix-darwin's defaults module.
        # Most defaults are set declaratively in system.defaults.CustomUserPreferences above;
        # this script covers the few that require ad-hoc commands (e.g. LSHandlers array-add).
        setAppleDefaults.text = ''
          # Disable creation of .DS_Store files on network volumes (SMB, NFS, etc.)
          defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

          # Suppress the "Are you sure you want to empty the Trash?" warning dialog
          defaults write com.apple.finder WarnOnEmptyTrash -bool false

          # Require password immediately (0s delay) after waking from sleep/screensaver
          defaults write com.apple.screensaver askForPassword -int 1
          defaults write com.apple.screensaver askForPasswordDelay -int 0

          # Register Neovide as the default handler for plain text files (public.plain-tex)
          defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerContentType=public.plain-text;LSHandlerRoleAll=com.neovide.neovide;}'

          # Disable telemetry & analytics services
          for service in \
            system/com.apple.analyticsd \
            system/com.apple.analyticsd.system \
            user/501/com.apple.diagnostics_agent \
            user/501/com.apple.diagnosticextensionsd \
            user/501/com.apple.inputanalyticsd \
            user/501/com.apple.feedbackd \
            user/501/com.apple.spindump_agent \
            system/com.apple.spindump \
            system/com.apple.tailspind \
            user/501/com.apple.geoanalyticsd \
            user/501/com.apple.ap.adprivacyd \
            user/501/com.apple.SubmitDiagInfo \
            user/501/com.apple.DiagnosticsReporter \
            user/501/com.apple.diagnosticspushd \
            user/501/com.apple.analyticsagent \
            user/501/com.apple.osanalyticshelper \
            user/501/com.apple.audioanalyticsd \
            user/501/com.apple.wifianalyticsd \
            user/501/com.apple.EcosystemAnalytics \
          ; do
            sudo launchctl disable "$service" 2>/dev/null || true
          done

          # Disable Apple Intelligence / ML model services (still load even with optIn=off)
          for service in \
            system/com.apple.generativeexperiencesd \
            user/501/com.apple.intelligenceplatformd \
            user/501/com.apple.intelligencetasksd \
            user/501/com.apple.intelligenceflowd \
            user/501/com.apple.intelligencecontextd \
            user/501/com.apple.mlhostd \
            user/501/com.apple.ModelCatalogAgent \
            system/com.apple.modelcatalogd \
            system/com.apple.modelmanagerd \
          ; do
            sudo launchctl disable "$service" 2>/dev/null || true
          done

          # Kill running processes that should no longer be active
          for proc in \
            analyticsd \
            diagnostics_agent \
            diagnosticextensionsd \
            inputanalyticsd \
            feedbackd \
            spindump_agent \
            tailspind \
            geoanalyticsd \
            adprivacyd \
            SubmitDiagInfo \
            DiagnosticsReporter \
            analyticsagent \
            osanalyticshelper \
            audioanalyticsd \
            wifianalyticsd \
            ecosystemanalyticsd \
            generativeexperiencesd \
            intelligenceplatformd \
            intelligencetasksd \
            intelligenceflowd \
            intelligencecontextd \
            mlhostd \
            ModelCatalogAgent \
            modelcatalogd \
            modelmanagerd \
          ; do
            pkill -x "$proc" 2>/dev/null || true
            pkill -x "$proc"d 2>/dev/null || true
          done
        '';
      };

      primaryUser = config.my.user.name;
    };

    launchd.daemons.my-pmset-settings = {
      script = ''
        # Low Power Mode (throttles CPU, network keepalives, background processes): 0 = disabled, 1 = enabled
        /usr/bin/pmset -c lowpowermode 0

        # Wake on Ethernet magic packet: 0 = disabled, 1 = enabled
        # Allows the machine to be woken remotely over the network
        /usr/bin/pmset -c womp 1

        # System sleep timer: value in minutes, or 0 to disable sleep entirely
        # Set to 0 so the machine never sleeps on AC power
        /usr/bin/pmset -c sleep 0

        # Disk spindown timer: value in minutes, or 0 to disable
        # Set to 0 to prevent disk sleeping, which can interfere with system wakefulness on AC
        /usr/bin/pmset -c disksleep 0

        # Power Nap: 0 = disabled, 1 = enabled (allows background network activity during display sleep)
        /usr/bin/pmset -c powernap 1

        # ── Battery power ───────────────────────────────────────────────────────
        # Everything above is scoped -c (AC). These are -b (battery). Nothing in
        # this repo declared battery settings before, so they were unmanaged
        # drift: a UI tweak or a macOS update could change them and a rebuild
        # would not put them back.
        #
        # Idle sleep on battery: sleep after 5 minutes. The live value was 0
        # (never), so an open lid on battery never slept and just drained.
        # Lid-close sleep is not governed by this: the lid is handled by
        # my-lid-ac-watch below.
        /usr/bin/pmset -b sleep 5

        # Display sleep on battery: 2 minutes, matching the previous live value
        # so declaring it does not change screen behaviour.
        /usr/bin/pmset -b displaysleep 2
      '';
      serviceConfig = {
        RunAtLoad = true; # apply settings immediately when the daemon loads at boot
        KeepAlive = false; # run once and exit, no need to keep the process running
      };
    };

    # Keep `disablesleep` in sync with the power source, so closing the lid keeps
    # the machine awake on AC power only.
    #
    # Why a daemon and not a pmset setting: `pmset` cannot scope `disablesleep` to
    # one power source. The -a/-b/-c flags are accepted but ignored for that key;
    # it is one system-wide flag. Setting it by hand therefore also disables lid
    # sleep on battery, which means a closed lid in a bag stays awake and drains.
    # This daemon does the scoping that pmset will not.
    #
    # Why `disablesleep` at all: `pmset sleep 0` only defeats the idle timer. Lid
    # close is a separate clamshell event that powerd turns into an immediate
    # sleep request regardless of the idle timer. `disablesleep` is the only
    # pmset knob that makes powerd ignore the clamshell request.
    launchd.daemons.my-lid-ac-watch = {
      # Runs as root (LaunchDaemon in the system domain), which pmset requires.
      script = ''
        set -u

        log() { /bin/echo "$(/bin/date -u +%Y-%m-%dT%H:%M:%SZ) $*"; }

        # Log only when the message changes, so a condition that stays broken
        # writes one line rather than one line every 20 seconds forever.
        last_msg=""
        note() {
          if [ "$1" != "$last_msg" ]; then
            log "$1"
            last_msg="$1"
          fi
        }

        # Current value of the system-wide disablesleep flag. `pmset -g` omits the
        # SleepDisabled line entirely when the flag is 0, so absence means 0.
        #
        # This is read back after every write because `pmset` exits 0 even when it
        # refuses the change, so its exit status proves nothing.
        read_disablesleep() {
          /usr/bin/pmset -g \
            | /usr/bin/awk '/SleepDisabled/ { print $2; found = 1 } END { if (!found) print 0 }'
        }

        # Read ExternalConnected from the IORegistry rather than parsing
        # `pmset -g ps`. The pmset output is localized, so it would break on a
        # non-English system locale. Prints Yes, No, or nothing.
        ac_state() {
          /usr/sbin/ioreg -rn AppleSmartBattery \
            | /usr/bin/awk -F' = ' '/"ExternalConnected"/ { gsub(/"/, "", $2); print $2; exit }'
        }

        # A LaunchDaemon starts as root; this fires only if someone runs the script
        # by hand, which would otherwise fail silently (see read_disablesleep).
        if [ "$(/usr/bin/id -u)" != 0 ]; then
          log "FATAL not running as root, pmset cannot apply anything; exiting"
          exit 1
        fi

        log "watcher starting, disablesleep=$(read_disablesleep)"

        while :; do
          state="$(ac_state)"
          case "$state" in
            Yes) want=1; source_name=ac ;;
            No)  want=0; source_name=battery ;;
            *)
              note "ERROR could not read ExternalConnected from IORegistry, leaving disablesleep untouched"
              /bin/sleep 20
              continue
              ;;
          esac

          current="$(read_disablesleep)"
          if [ "$current" != "$want" ]; then
            result="$(/usr/bin/pmset -a disablesleep "$want" 2>&1)"
            rc=$?
            current="$(read_disablesleep)"
            if [ "$current" = "$want" ]; then
              note "$source_name (ExternalConnected=$state) -> disablesleep=$want"
            else
              note "ERROR pmset -a disablesleep $want did not take effect (now=$current rc=$rc output=$result)"
            fi
          fi

          # Plain polling sleep, not a launchd StartInterval timer: this process
          # holds no power assertion and does not wake the system, so it costs
          # nothing while the machine sleeps.
          /bin/sleep 20
        done
      '';
      serviceConfig = {
        RunAtLoad = true; # apply the correct value at boot, before any lid close
        KeepAlive = true; # must stay resident to react to plug and unplug
        ThrottleInterval = 10; # if it crashes, do not respawn in a tight loop
        StandardOutPath = "/var/log/my-lid-ac-watch.log";
        StandardErrorPath = "/var/log/my-lid-ac-watch.log";
        ProcessType = "Background";
        Nice = 10;
      };
    };
  };
}
