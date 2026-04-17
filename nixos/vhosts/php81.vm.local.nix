# Virtual host for php81.vm.local
# PHP-FPM pool: phpfpm-php81  (defined in ../php-fpm.nix)
#
# To add a new virtual host, copy this file, rename it, and:
#   1. Update serverName, root, and the phpfpm socket path.
#   2. Add the pool to ../php-fpm.nix.
#   3. Add the file to the vhosts list in ../nginx.nix.
{ config, ... }:
{
  serverName = "php81.vm.local";
  root = "/home/tung/php-sites/php81";
  extraConfig = "index index.php;";

  locations."/" = {
    extraConfig = ''
      try_files $uri $uri/ /index.php?$query_string;
    '';
  };

  locations."~ \\.php$" = {
    extraConfig = ''
      include ${config.services.nginx.package}/conf/fastcgi_params;
      include ${config.services.nginx.package}/conf/fastcgi.conf;
      fastcgi_index index.php;
      fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
      fastcgi_pass unix:${config.services.phpfpm.pools.php81.socket};
    '';
  };
}
