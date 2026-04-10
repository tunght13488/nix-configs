# nixos/php-fpm.nix — PHP-FPM pools for each PHP version
#
# Pools run as user `tung` (same owner as the site files under ~/php-sites/).
# The nginx user is added to the `tung` group via users.users.nginx.extraGroups
# so it can communicate via the Unix socket.
#
# To add a new pool:
#   1. Add a new attribute under services.phpfpm.pools below.
#   2. Create the matching virtual host in nixos/vhosts/<yoursite>.local.nix.
{ lib, pkgs, ... }:
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
  systemd.services = {
    phpfpm-php81.serviceConfig.ProtectHome = lib.mkForce false;
    phpfpm-php82.serviceConfig.ProtectHome = lib.mkForce false;
    phpfpm-php83.serviceConfig.ProtectHome = lib.mkForce false;
  };

}
