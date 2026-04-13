# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  # You can import other home-manager modules here
  imports = [
    # If you want to use home-manager modules from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModule
    inputs.nixvim.homeModules.nixvim

    # You can also split up your configuration and import pieces of it here:
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
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default
      inputs.phps.overlays.default

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
  home.packages =
    with pkgs;
    [
      ncdu
      monaspace
      nerd-fonts.monaspace
      httpie
      colormake
      gnumake
      jetbrains-toolbox
      mycli
      postman
    ]
    # ++ (
    #   let
    #     inherit (pkgs.jetbrains) phpstorm;
    #     plugins = inputs.nix-jetbrains-plugins.lib.pluginsForIde pkgs phpstorm [
    #       "com.github.copilot"
    #     ];
    #   in
    #   [
    #     # phpstorm
    #     (pkgs.jetbrains.plugins.addPlugins phpstorm (lib.attrValues plugins))
    #   ]
    # )
    # ++ (
    #   let
    #     inherit (pkgs.jetbrains) idea;
    #     plugins = inputs.nix-jetbrains-plugins.lib.pluginsForIde pkgs idea [
    #       "com.github.copilot"
    #     ];
    #   in
    #   [
    #     # idea
    #     (pkgs.jetbrains.plugins.addPlugins idea (lib.attrValues plugins))
    #   ]
    # )
    ++ (
      # PHP versions from nix-phps.
      # Each version gets versioned binary names, e.g.:
      #   php81, php81-fpm, php81ize, php81-config
      #   php82, php82-fpm, php82ize, php82-config
      #   php83, php83-fpm, php83ize, php83-config
      #
      # Run FPM for multiple versions simultaneously on different ports:
      #   php81-fpm --nodaemonize -d listen=127.0.0.1:9081
      #   php82-fpm --nodaemonize -d listen=127.0.0.1:9082
      #   php83-fpm --nodaemonize -d listen=127.0.0.1:9083
      #
      # Switch the default `php` by changing the php83 reference in the hiPrio block below.
      let
        mkVersionedPhp =
          ver: php:
          pkgs.runCommand "php${ver}-versioned" { } ''
            mkdir -p $out/bin
            for src in ${php}/bin/php ${php}/bin/php-fpm ${php}/bin/php-cgi ${php}/bin/phpdbg ${php}/bin/phpize ${php}/bin/php-config; do
              [ -e "$src" ] || continue
              base=$(basename "$src")
              # php → php81, php-fpm → php81-fpm, phpize → php81ize, php-config → php81-config
              versioned=$(echo "$base" | sed "s/^php/php${ver}/")
              ln -s "$src" "$out/bin/$versioned"
            done
          '';
      in
      [
        (mkVersionedPhp "81" pkgs.php81)
        (mkVersionedPhp "82" pkgs.php82)
        (mkVersionedPhp "83" pkgs.php83)
        # Default `php` / `php-fpm` point to 8.3 — change pkgs.php83 here to switch.
        (lib.hiPrio pkgs.php83)
        (lib.hiPrio pkgs.php83.packages.composer)
      ]
    );

  programs.nixvim.imports = [ ./nixvim.nix ];

  # direnv — auto-switch PHP version per project via .envrc
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # PHP test sites — served by system nginx (nixos/nginx.nix).
  # Each directory is made world-readable (o+rx) so the nginx user can read files.
  home.file = {
    "php-sites/php81/index.php".text = "<?php phpinfo(); phpinfo(INFO_MODULES);";
    "php-sites/php82/index.php".text = "<?php phpinfo(); phpinfo(INFO_MODULES);";
    "php-sites/php83/index.php".text = "<?php phpinfo(); phpinfo(INFO_MODULES);";
  };

  home.activation.phpSitesDirPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Make directories world-readable so the nginx user can traverse them.
    # The index.php files are symlinks into the Nix store which is already
    # world-readable (store files are 444), so no chmod on those is needed.
    chmod o+rx \
      "$HOME/php-sites" \
      "$HOME/php-sites/php81" \
      "$HOME/php-sites/php82" \
      "$HOME/php-sites/php83"
  '';

  # Enable home-manager and git
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.11";
}
