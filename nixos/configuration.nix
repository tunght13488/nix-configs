# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        # Enable flakes and new 'nix' command
        experimental-features = "nix-command flakes";
        # Opinionated: disable global registry
        flake-registry = "";
        # Workaround for https://github.com/NixOS/nix/issues/9574
        nix-path = config.nix.nixPath;
        # Cache configuration - optimized for Asia
        substituters = [
          # "https://mirror.sjtu.edu.cn/nix-channels/store" # Shanghai Jiao Tong University - best for Asia
          # "https://mirrors.ustc.edu.cn/nix-channels/store" # USTC backup mirror
          # "https://cache.nixos.org" # Official global cache
          "https://nix-community.cachix.org" # Community packages
          # "https://hyprland.cachix.org"
          # "https://aseipp-nix-cache.global.ssl.fastly.net"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
        http-connections = 120;
        max-substitution-jobs = 120;
        max-jobs = "auto";
      };
      # Opinionated: disable channels
      # channel.enable = false;

      # Opinionated: make flake registry and nix path match flake inputs
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

  networking = {
    hostName = "nixos-vmware";
    networkmanager.enable = true;
  };

  time.timeZone = "Asia/Singapore";

  users.users = {
    tung = {
      initialHashedPassword = "$y$j9T$/dk6Un7glSRNrZAI.PaJI/$qReZjapopysGOwT.YKGT9slxIXbFeCklCW5W6LXw112";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [ ];
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
      shell = pkgs.zsh;
    };
  };

  # # This setups a SSH server. Very important if you're setting up a headless system.
  # # Feel free to remove if you don't need it.
  # services.openssh = {
  #   enable = true;
  #   settings = {
  #     # Opinionated: forbid root login through SSH.
  #     PermitRootLogin = "no";
  #     # Opinionated: use keys only.
  #     # Remove if you want to SSH using passwords
  #     PasswordAuthentication = false;
  #   };
  # };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";

  # VMWare Guest
  services.xserver = {
    enable = true;
    videoDrivers = [ "vmware" ];
  };
  virtualisation.vmware.guest.enable = true;

  # GNOME
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  # services.gnome.core-apps.enable = false;
  # services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-user-docs
  ];

  # programs.firefox.enable = true;
  # programs.firefox = {
  #   enable = true;

  #   policies = {
  #     DisableTelemetry = true;
  #   };
  # };

  programs.vim.enable = true;
  programs.zsh.enable = true;
  programs.git.enable = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = [ "tung" ];
  };

  # nixpkgs.config.allowUnfreePredicate =
  #   pkg:
  #   builtins.elem (lib.getName pkg) [
  #     "vscode"
  #     "1password-gui"
  #     "1password-cli"
  #     "1password"
  #     "google-chrome"
  #   ];

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    # wget
    git
    vscode
    # firefox
    google-chrome
    nixfmt
    stow
    home-manager
  ];
}
