# Virtual host for php83.vm.local
# PHP-FPM pool: phpfpm-php83  (defined in ../php-fpm.nix)
{ config, ... }:
{
  serverName = "php83.vm.local";
  root = "/home/tung/php-sites/php83";
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
      fastcgi_pass unix:${config.services.phpfpm.pools.php83.socket};
    '';
  };
}
