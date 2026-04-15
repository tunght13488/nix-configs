# nixos/php-fpm.nix — PHP-FPM pools for each PHP version
#
# Pools run as user `tung` (same owner as the site files under ~/php-sites/).
# The nginx user is added to the `tung` group via users.users.nginx.extraGroups
# so it can communicate via the Unix socket.
#
# To add a new pool:
#   1. Add a new attribute under services.phpfpm.pools below.
#   2. Create the matching virtual host in nixos/vhosts/<yoursite>.local.nix.
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

  defaultPoolSettings = {
    "pm" = "dynamic";
    "pm.max_children" = 8;
    "pm.start_servers" = 1;
    "pm.min_spare_servers" = 1;
    "pm.max_spare_servers" = 2;
    "listen.owner" = "nginx";
    "listen.group" = "nginx";
    "listen.mode" = "0660";
    "catch_workers_output" = "yes";
    "php_admin_flag[log_errors]" = "on";
  };
in
{
  services.phpfpm.pools = {
    php81 = {
      user = "tung";
      group = "users";
      phpPackage = v81.phpPkg;
      settings = defaultPoolSettings;
    };

    php82 = {
      user = "tung";
      group = "users";
      phpPackage = v82.phpPkg;
      settings = defaultPoolSettings;
    };

    php83 = {
      user = "tung";
      group = "users";
      phpPackage = v83.phpPkg;
      settings = defaultPoolSettings;
    };
  };

  # Let nginx talk to the FPM sockets (which are owned nginx:nginx)
  # and read files under /home/tung/php-sites/ (which are o+rx).
  users.users.nginx.extraGroups = [ "users" ];

  # The NixOS phpfpm module sets ProtectHome=true on each pool's systemd service,
  # which would prevent FPM workers from opening scripts in ~/php-sites/.
  # Override that for all three pools.
  #
  # PHP_INI_SCAN_DIR must be a process-level env var (not an FPM pool env[...])
  # so that php-fpm reads the custom .ini files at startup, before pool config
  # is processed.  This gives FPM workers the FPM-specific INI settings.
  systemd.services = {
    phpfpm-php81 = {
      serviceConfig.ProtectHome = lib.mkForce false;
      environment.PHP_INI_SCAN_DIR = v81.fpmIniScanDir;
    };
    phpfpm-php82 = {
      serviceConfig.ProtectHome = lib.mkForce false;
      environment.PHP_INI_SCAN_DIR = v82.fpmIniScanDir;
    };
    phpfpm-php83 = {
      serviceConfig.ProtectHome = lib.mkForce false;
      environment.PHP_INI_SCAN_DIR = v83.fpmIniScanDir;
    };
  };
}
