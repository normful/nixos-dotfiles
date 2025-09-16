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
      description = "Machine hostname";
    };

    user.name = lib.mkOption {
      type = lib.types.str;
      description = "Primary user name";
    };

    isFirstInstall = lib.mkOption {
      type = lib.types.bool;
      description = "First system install";
      default = false;
    };

    flakePath = lib.mkOption {
      description = "System flake path";
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
      description = "Interactive CLI tools";
      default = false;
    };

    enableFullNeovim = lib.mkOption {
      type = lib.types.bool;
      description = "Full Neovim setup";
      default = false;
    };

    enableAiCodingAgents = lib.mkOption {
      type = lib.types.bool;
      description = "AI coding agent packages";
      default = false;
    };

    enableLangTsJs = lib.mkOption {
      type = lib.types.bool;
      description = "TypeScript/JavaScript packages";
      default = false;
    };

    enableLangGo = lib.mkOption {
      type = lib.types.bool;
      description = "Go development packages";
      default = false;
    };

    enableLangRust = lib.mkOption {
      type = lib.types.bool;
      description = "Rust development packages";
      default = false;
    };

    enableLangPython = lib.mkOption {
      type = lib.types.bool;
      description = "Python development packages";
      default = false;
    };

    enableLangC = lib.mkOption {
      type = lib.types.bool;
      description = "C/C++ development packages";
      default = false;
    };

    enableLangBash = lib.mkOption {
      type = lib.types.bool;
      description = "Bash development packages";
      default = false;
    };

    enableLangRuby = lib.mkOption {
      type = lib.types.bool;
      description = "Ruby development packages";
      default = false;
    };

    enableLangCss = lib.mkOption {
      type = lib.types.bool;
      description = "CSS development packages";
      default = false;
    };

    enableLangPhp = lib.mkOption {
      type = lib.types.bool;
      description = "PHP development packages";
      default = false;
    };

    enableLangLua = lib.mkOption {
      type = lib.types.bool;
      description = "Lua development packages";
      default = false;
    };

    enableLangNix = lib.mkOption {
      type = lib.types.bool;
      description = "Nix development packages";
      default = false;
    };

    enableLangGleam = lib.mkOption {
      type = lib.types.bool;
      description = "Gleam development packages";
      default = false;
    };

    enableLangErlang = lib.mkOption {
      type = lib.types.bool;
      description = "Erlang development packages";
      default = false;
    };

    enableLangUml = lib.mkOption {
      type = lib.types.bool;
      description = "UML development packages";
      default = false;
    };

    enableLangTypst = lib.mkOption {
      type = lib.types.bool;
      description = "Typst development packages";
      default = false;
    };

    enableDocker = lib.mkOption {
      type = lib.types.bool;
      description = "Docker and container tools";
      default = false;
    };

    enableNetworkingTools = lib.mkOption {
      type = lib.types.bool;
      description = "Networking and DNS tools";
      default = false;
    };

    enableFileSyncTools = lib.mkOption {
      type = lib.types.bool;
      description = "File sync tools";
      default = false;
    };

    enableBackupTools = lib.mkOption {
      type = lib.types.bool;
      description = "Backup tools";
      default = false;
    };

    enablePdfTools = lib.mkOption {
      type = lib.types.bool;
      description = "PDF processing tools";
      default = false;
    };

    enableLogTools = lib.mkOption {
      type = lib.types.bool;
      description = "Log viewing and analysis tools";
      default = false;
    };

    enableJujutsu = lib.mkOption {
      type = lib.types.bool;
      description = "Jujutsu VCS tools";
      default = false;
    };

    enableJsonTools = lib.mkOption {
      type = lib.types.bool;
      description = "JSON processing tools";
      default = false;
    };

    enableGitTools = lib.mkOption {
      type = lib.types.bool;
      description = "Git version control tools";
      default = false;
    };

    enableAudioVideoTools = lib.mkOption {
      type = lib.types.bool;
      description = "Audio and video processing tools";
      default = false;
    };

    enableImageTools = lib.mkOption {
      type = lib.types.bool;
      description = "Image processing and manipulation tools";
      default = false;
    };

    enableScreenSharingTools = lib.mkOption {
      type = lib.types.bool;
      description = "Screen sharing and remote access tools";
      default = false;
    };
  };
}
