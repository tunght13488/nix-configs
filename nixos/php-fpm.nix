# nixos/php-fpm.nix — PHP-FPM pools for each PHP version
#
# Pools run as user `tung` (same owner as the site files under ~/php-sites/).
# The nginx user is added to the `tung` group via users.users.nginx.extraGroups
# so it can communicate via the Unix socket.
#
# To add a new pool:
#   1. Add a new attribute under services.phpfpm.pools below.
#   2. Create the matching virtual host in nixos/vhosts/<yoursite>.local.nix.
{
  lib,
  pkgs,
  phpCustomIniContent,
  php81IniContent,
  php82IniContent,
  php83IniContent,
  ...
}:
let
  # Mirror the same mkIniDir / phpIniScanDir helpers used in devshells and
  # home-manager so FPM workers see identical ini files.
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
in
{
  services.phpfpm.pools = {
    php81 = {
      user = "tung";
      group = "users";
      phpPackage = pkgs.php81;
      settings = {
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
    };

    php82 = {
      user = "tung";
      group = "users";
      phpPackage = pkgs.php82;
      settings = {
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
    };

    php83 = {
      user = "tung";
      group = "users";
      phpPackage = pkgs.php83;
      settings = {
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
  # is processed.  This gives FPM workers identical INI settings to the
  # home-manager CLI wrappers and devshell environments.
  systemd.services = {
    phpfpm-php81 = {
      serviceConfig.ProtectHome = lib.mkForce false;
      environment.PHP_INI_SCAN_DIR = phpIniScanDir pkgs.php81 php81CustomIni;
    };
    phpfpm-php82 = {
      serviceConfig.ProtectHome = lib.mkForce false;
      environment.PHP_INI_SCAN_DIR = phpIniScanDir pkgs.php82 php82CustomIni;
    };
    phpfpm-php83 = {
      serviceConfig.ProtectHome = lib.mkForce false;
      environment.PHP_INI_SCAN_DIR = phpIniScanDir pkgs.php83 php83CustomIni;
    };
  };

}
