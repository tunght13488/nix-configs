# PHP versioned CLI wrappers and test sites
{ config
, lib
, pkgs
, ...
}:
let
  php = config.phpConfig._lib;
  v81 = php.versions.php81;
  v82 = php.versions.php82;
  v83 = php.versions.php83;
in
{
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
  # Switch the default `php` by changing the v83 references in the hiPrio blocks below.
  home.packages = [
    v81.versionedPkg
    v82.versionedPkg
    v83.versionedPkg
    # Default `php` / `php-fpm` point to 8.3 — change v83 here to switch.
    (lib.hiPrio v83.defaultPkg)
    (lib.hiPrio v83.composerPkg)
  ];

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
}
