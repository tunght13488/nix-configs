# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  phpCustomIniContent,
  php81IniContent,
  php82IniContent,
  php83IniContent,
  ...
}:
let
  # Build a scan-dir derivation from an INI content string.
  mkIniDir =
    name: content:
    pkgs.writeTextFile {
      inherit name;
      text = content;
      destination = "/custom.ini";
    };

  phpCustomIni = mkIniDir "php-custom-ini" phpCustomIniContent;
  php81CustomIni = mkIniDir "php81-custom-ini" php81IniContent;
  php82CustomIni = mkIniDir "php82-custom-ini" php82IniContent;
  php83CustomIni = mkIniDir "php83-custom-ini" php83IniContent;

  # php/lib contains the Nix-generated php.ini with all extension= lines.
  phpIniScanDir = php: versionIni: "${php}/lib:${phpCustomIni}:${versionIni}";

  # Creates versioned wrapper scripts (php81, php81-fpm, php81ize, …) that set
  # PHP_INI_SCAN_DIR before exec-ing the real binary.
  mkVersionedPhp =
    ver: php: versionIni:
    pkgs.runCommand "php${ver}-versioned" { } ''
      mkdir -p $out/bin
      for src in ${php}/bin/php ${php}/bin/php-fpm ${php}/bin/php-cgi ${php}/bin/phpdbg ${php}/bin/phpize ${php}/bin/php-config; do
        [ -e "$src" ] || continue
        base=$(basename "$src")
        # php → php81, php-fpm → php81-fpm, phpize → php81ize, php-config → php81-config
        versioned=$(echo "$base" | sed "s/^php/php${ver}/")
        printf '#!/bin/sh\nexport PHP_INI_SCAN_DIR="${phpIniScanDir php versionIni}"\nexec "%s" "$@"\n' \
          "$src" > "$out/bin/$versioned"
        chmod +x "$out/bin/$versioned"
      done
    '';

  # Wraps the default (non-versioned) php/php-fpm/… binaries with PHP_INI_SCAN_DIR.
  mkDefaultPhpWithIni =
    php: versionIni:
    pkgs.runCommand "php-default-with-ini" { } ''
      mkdir -p $out/bin
      for src in ${php}/bin/php ${php}/bin/php-fpm ${php}/bin/php-cgi ${php}/bin/phpdbg ${php}/bin/phpize ${php}/bin/php-config; do
        [ -e "$src" ] || continue
        name=$(basename "$src")
        printf '#!/bin/sh\nexport PHP_INI_SCAN_DIR="${phpIniScanDir php versionIni}"\nexec "%s" "$@"\n' \
          "$src" > "$out/bin/$name"
        chmod +x "$out/bin/$name"
      done
    '';
in
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
    ./ngrok.nix
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
      # Each version gets versioned wrapper scripts, e.g.:
      #   php81, php81-fpm, php81ize, php81-config
      #   php82, php82-fpm, php82ize, php82-config
      #   php83, php83-fpm, php83ize, php83-config
      #
      # Run FPM for multiple versions simultaneously on different ports:
      #   php81-fpm --nodaemonize -d listen=127.0.0.1:9081
      #   php82-fpm --nodaemonize -d listen=127.0.0.1:9082
      #   php83-fpm --nodaemonize -d listen=127.0.0.1:9083
      #
      # Switch the default `php` by changing the php83 references in the hiPrio blocks below.
      [
        (mkVersionedPhp "81" pkgs.php81 php81CustomIni)
        (mkVersionedPhp "82" pkgs.php82 php82CustomIni)
        (mkVersionedPhp "83" pkgs.php83 php83CustomIni)
        # Default `php` / `php-fpm` point to 8.3 — change pkgs.php83 here to switch.
        (lib.hiPrio (mkDefaultPhpWithIni pkgs.php83 php83CustomIni))
        (lib.hiPrio (
          pkgs.writeShellScriptBin "composer" ''
            export PHP_INI_SCAN_DIR="${phpIniScanDir pkgs.php83 php83CustomIni}"
            exec ${pkgs.php83.packages.composer}/bin/composer "$@"
          ''
        ))
      ]);

  programs.nixvim.imports = [ ./nixvim.nix ];

  # direnv — auto-switch PHP version per project via .envrc
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # agenix secret — decrypted at activation to $XDG_RUNTIME_DIR/agenix/
  age.identityPaths = [
    "/home/tung/.ssh/ssh_agenix"
  ];
  age.secrets.ngrok-authtoken.file = ../secrets/ngrok-authtoken.age;

  # ngrok — managed tunnel config; authtoken injected from agenix secret
  programs.ngrok = {
    enable = true;
    authtokenFile = config.age.secrets.ngrok-authtoken.path;
    endpoints = {
      middleware = {
        name = "middleware";
        url = "https://inherently-good-tarpon.ngrok-free.app";
        upstream.url = "middleware.vm.local:443";
      };
    };
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
