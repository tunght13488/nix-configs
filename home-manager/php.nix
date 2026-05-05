# PHP versioned CLI wrappers and test sites
{ lib
, ...
}:
{
  # Keep the user-level defaults lightweight: link `php`/`composer` to the
  # system-managed 8.3 wrappers instead of installing duplicate packages.
  home.sessionPath = [ "$HOME/.local/bin" ];

  home.file = {
    ".local/bin/php" = {
      text = ''
        #!/bin/sh
        exec /run/current-system/sw/bin/php83 "$@"
      '';
      executable = true;
    };

    ".local/bin/composer" = {
      text = ''
        #!/bin/sh
        exec /run/current-system/sw/bin/composer83 "$@"
      '';
      executable = true;
    };

    # PHP test sites — served by system nginx (nixos/nginx.nix).
    # Each directory is made world-readable (o+rx) so the nginx user can read files.
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
