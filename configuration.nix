{ config, pkgs, nixpkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration-parallels.nix
    ];

  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnsupportedSystem = true;
  };

  hardware.video.hidpi.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "0";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;

  boot.kernel.sysctl."vm.swappiness" = 0;

  networking.hostName = "dev";
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh = {
    enable = true;
    passwordAuthentication = true;
    permitRootLogin = "no";
  };

  networking.firewall.enable = false;

  environment.systemPackages = with pkgs; [
    xstow
    gnumake
    killall

    git
    delta

    curl
    wget

    htop
    tree

    kitty
    tmux # TODO(norman): Make a new minimal working ~/.tmux.conf

    neovim
    nodePackages.neovim

    hstr
    zoxide
    fzf
    ripgrep

    jq

    tree-sitter

    # Nix
    rnix-lsp

    # Go
    go
    gopls

    # JS/TS
    nodejs
    yarn
    nodePackages.prettier
    lua
    pandoc
    nodePackages.typescript-language-server

    # Python
    python310
    python310Packages.python-lsp-server
    poetry

    # Ruby
    ruby

    # Haskell
    haskellPackages.haskell-language-server

    # Bash
    nodePackages.bash-language-server

    # YAML
    nodePackages.yaml-language-server

    # Dockerfile
    nodePackages.dockerfile-language-server-nodejs

    # Perl
    perl

    # C
    gcc
  ];

  environment.variables = {
    EDITOR = "nvim";
    GIT_EDITOR = "nvim";
    TERMINAL = "kitty";
  };

  users.users.norman = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPassword = "$6$Dx/3q4A5r.F4vbUV$lHfQYSz78P8dzazTd.oh.dg1E9Y1Wy/pDoXYV2ZZ0O94xjh5YupqDLTTgiTAATqOApqEPXxU3EbSztv7LY.ez.";
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKVybE7AKV3Qe55/Rar3DjdwryLOb5HWFhTuaL+B82kT norman_macbook_pro_m1_pro" ];
    shell = pkgs.fish;
  };

  services.xserver = {
    enable = true;
    autorun = true;
    layout = "us";
    dpi = 254;

    libinput = {
      enable = true;
      touchpad.disableWhileTyping = true;
    };

    displayManager = {
      defaultSession = "none+i3";
      autoLogin = { enable = true; user = "norman"; };
      sessionCommands = ''
        ${pkgs.xorg.xset}/bin/xset r rate 200 40
        ${pkgs.xorg.xrandr}/bin/xrandr --newmode "3024x1964_120.00"  1071.50  3024 3296 3632 4240  1964 1967 1977 2106 -hsync +vsync
        ${pkgs.xorg.xrandr}/bin/xrandr --addmode "Virtual-1" "3024x1964_120.00"
        ${pkgs.xorg.xrandr}/bin/xrandr --output "Virtual-1" --mode "3024x1964_120.00"
      '';
    };

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [ dmenu i3status ];
    };
  };

  fonts.fontconfig.subpixel.lcdfilter = "none";

  programs.fish = {
    enable = true;
    shellAbbrs = {
      c = "clear";
      q = "exit";

      l = "ls -lhAtr --color=always";
      t = "tree -N -ashFC -I '.git|node_modules'";

      utc = "date -u";

      ag = "rg";

      g = "git";
      qg = "git";
      gl = "git l";
      gs = "git s";

      v  = "nvim";
      vi = "nvim";
      nv = "nvim";
      vim = "nvim";

      ea = "nvim $HOME/nixos-dotfiles/configuration.nix";
      eg = "nvim $HOME/nixos-dotfiles/norman/.gitconfig";
      ev = "nvim $HOME/nixos-dotfiles/norman/.config/nvim/lua/plugins.lua";
      ek = "nvim $HOME/nixos-dotfiles/norman/.config/kitty/kitty.conf";
      ef = "nvim $HOME/nixos-dotfiles/norman/.config/fish/config.fish";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

  # TODO(norman): Fix tree-sitter nvim error
  # TODO(norman): Fix parallels guest copy/paste maybe with https://github.com/wegank/nixos-config
}
