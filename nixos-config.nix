{
  nixpkgs-stable,
  nixpkgs-pinned-unstable,
  pkgs-stable,
  pkgs-pinned-unstable,
  ...
}:

{
  system.stateVersion = "25.05";

  nix = {
    package = pkgs-stable.nixVersions.latest;
    settings = {
      max-jobs = 8; # Adjust based on your CPU cores
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      keep-outputs = true;
      keep-derivations = true;
      keep-failed = false;
      keep-going = true;
      auto-optimise-store = false;
    };
    gc = {
      automatic = true;
      dates = "weekly";
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
    hostName = "lilac";
    networkmanager.enable = true;
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
  };

  time.timeZone = "UTC";

  i18n.defaultLocale = "en_US.UTF-8";

  environment = {
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
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };

  users = {
    users.norman = {
      isNormalUser = true;
      description = "Norman";
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
      ];
      shell = pkgs-stable.fish;
    };
  };

  security.sudo.wheelNeedsPassword = true;

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };
}
