{ config, pkgs, nixpkgs, ... }:

let
  macHostSshPublicKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKVybE7AKV3Qe55/Rar3DjdwryLOb5HWFhTuaL+B82kT norman_macbook_pro_m1_pro" ];
in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration-parallels.nix
    ];

  nix.settings.experimental-features = "nix-command flakes";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  hardware.video.hidpi.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Only use swap when running out of RAM
  boot.kernel.sysctl."vm.swappiness" = 0;

  networking.hostName = "dev";
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # Packages installed in the system profile
  environment.systemPackages = with pkgs; [
    gnumake
    git
    curl
    wget
    htop
    tmux
    neovim
    kitty
    xstow
  ];

  environment.variables = {
    EDITOR = "nvim";
    TERMINAL = "kitty";
  };

  users.users.root.openssh.authorizedKeys.keys = macHostSshPublicKeys;

  users.users.norman = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = with pkgs; [
      jq
      fzf
      silver-searcher
    ];
    hashedPassword = "$6$Dx/3q4A5r.F4vbUV$lHfQYSz78P8dzazTd.oh.dg1E9Y1Wy/pDoXYV2ZZ0O94xjh5YupqDLTTgiTAATqOApqEPXxU3EbSztv7LY.ez.";
    openssh.authorizedKeys.keys = macHostSshPublicKeys;
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
        ${pkgs.xorg.set}/bin/xset r rate 200 40
        ${pkgs.xorg.xrandr}/bin/xrandr -r s '3024x1964'
      '';
    };

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [ dmenu ];
    };
  };

  fonts.fontconfig.subpixel.lcdfilter = "none";

  services.openssh = {
    enable = true;
    passwordAuthentication = true;
    permitRootLogin = "yes";
  };

  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
