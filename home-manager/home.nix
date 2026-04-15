# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{ inputs
, pkgs
, ...
}:
{
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    inputs.self.homeManagerModules.ngrok
    inputs.self.homeManagerModules.php-config

    # Or modules exported from other flakes:
    inputs.nixvim.homeModules.nixvim

    # You can also split up your configuration and import pieces of it here:
    ./agenix.nix
    ./ngrok.nix
    ./php.nix
    ./ssh.nix
    ./git.nix
    ./zsh.nix
    ./tmux.nix
    ./fonts.nix
    ./terminal.nix
    ./ai.nix
    ./aws.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      inputs.self.overlays.additions
      inputs.self.overlays.modifications
      inputs.self.overlays.unstable-packages
      inputs.self.overlays.phps

      # You can also add overlays exported from other flakes:
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
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  home = {
    username = "tung";
    homeDirectory = "/home/tung";
  };

  # Add stuff for your user as you see fit:
  home.packages = with pkgs; [
    ncdu
    monaspace
    nerd-fonts.monaspace
    httpie
    gnumake
    jetbrains-toolbox
    mycli
    postman
    nodejs
    unstable.openspec
    (pkgs.lib.hiPrio jdk8)
    maven363
  ];

  home.sessionVariables = {
    JAVA_HOME = "${pkgs.jdk8}";
  };

  programs.nixvim.imports = [ ./nixvim.nix ];

  # direnv — auto-switch PHP version per project via .envrc
  programs.direnv.enable = true;
  programs.direnv.enableZshIntegration = true;
  programs.direnv.nix-direnv.enable = true;

  # Enable home-manager and git
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.11";
}
