{
  config,
  lib,
  pkgs-stable,
  ...
}:
let
  isDarwin = pkgs-stable.stdenv.isDarwin;
in
{
  options.my = {
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "The hostname to use for this machine.";
    };

    user.name = lib.mkOption {
      type = lib.types.str;
      description = "The name of the primary non-root user.";
    };

    isFirstInstall = lib.mkOption {
      type = lib.types.bool;
      description = "Whether this is the first installation of the system";
      default = false;
    };

    flakePath = lib.mkOption {
      description = "Path to the system flake";
      type = lib.types.str;
      default =
        if isDarwin then
          "/Users/${config.my.user.name}/code/nixos-dotfiles"
        else if config.my.isFirstInstall then
          "/etc/nixos"
        else
          "/home/${config.my.user.name}/code/nixos-dotfiles";
    };

    enableInteractiveCli = lib.mkOption {
      type = lib.types.bool;
      description = "Enable tools for interactive command line interface usage";
      default = false;
    };

    enableFullNeovim = lib.mkOption {
      type = lib.types.bool;
      description = "Install Neovim configured with many extras";
      default = false;
    };

    enableAiCodingAgents = lib.mkOption {
      type = lib.types.bool;
      description = "Install packages for AI coding agents";
      default = false;
    };

    enableLangTsJs = lib.mkOption {
      type = lib.types.bool;
      description = "Install packages related to TypeScript and JavaScript development";
      default = false;
    };

    enableLangGo = lib.mkOption {
      type = lib.types.bool;
      description = "Install packages related to Go development";
      default = false;
    };

    enableLangRust = lib.mkOption {
      type = lib.types.bool;
      description = "Install packages related to Rust development";
      default = false;
    };

    enableLangPython = lib.mkOption {
      type = lib.types.bool;
      description = "Install packages related to Python development";
      default = false;
    };

    enableLangBash = lib.mkOption {
      type = lib.types.bool;
      description = "Install packages related to Bash development";
      default = false;
    };

    enableLangRuby = lib.mkOption {
      type = lib.types.bool;
      description = "Install packages related to Ruby development";
      default = false;
    };

    enableLangCss = lib.mkOption {
      type = lib.types.bool;
      description = "Install packages related to CSS development";
      default = false;
    };

    enableLangPhp = lib.mkOption {
      type = lib.types.bool;
      description = "Install packages related to PHP development";
      default = false;
    };

    enableLangLua = lib.mkOption {
      type = lib.types.bool;
      description = "Install packages related to Lua development";
      default = false;
    };

    enableLangNix = lib.mkOption {
      type = lib.types.bool;
      description = "Install packages related to Nix development";
      default = false;
    };

    enableLangGleam = lib.mkOption {
      type = lib.types.bool;
      description = "Install packages related to Gleam development";
      default = false;
    };

    enableLangErlang = lib.mkOption {
      type = lib.types.bool;
      description = "Install packages related to Erlang development";
      default = false;
    };

    enableLangUml = lib.mkOption {
      type = lib.types.bool;
      description = "Install packages related to UML development";
      default = false;
    };

    enableLangTypst = lib.mkOption {
      type = lib.types.bool;
      description = "Install packages related to Typst development";
      default = false;
    };

    enableDocker = lib.mkOption {
      type = lib.types.bool;
      description = "Install Docker and related container tools";
      default = false;
    };

    enableNetworkingTools = lib.mkOption {
      type = lib.types.bool;
      description = "Install networking and DNS tools";
      default = false;
    };

    enableFileSyncTools = lib.mkOption {
      type = lib.types.bool;
      description = "Install file synchronization and backup tools";
      default = false;
    };

    enablePdfTools = lib.mkOption {
      type = lib.types.bool;
      description = "Install PDF processing and manipulation tools";
      default = false;
    };

    enableLogTools = lib.mkOption {
      type = lib.types.bool;
      description = "Install log file viewing and analysis tools";
      default = false;
    };

    enableJujutsu = lib.mkOption {
      type = lib.types.bool;
      description = "Install Jujutsu VCS and related tools";
      default = false;
    };

    enableJsonTools = lib.mkOption {
      type = lib.types.bool;
      description = "Install JSON processing and manipulation tools";
      default = false;
    };
  };
}
