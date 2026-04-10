{ config, ... }:
{
  serverName = "middleware.vm.local";
  root = "/home/tung/code/netsuite-middleware/public";
  extraConfig = ''
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    index index.php;
    charset utf-8;
    error_page 404 /index.php;
    error_log /var/log/nginx/middleware.vm.local_error.log;
    access_log /var/log/nginx/middleware.vm.local_access.log;
  '';

  locations."/" = {
    extraConfig = ''
      try_files $uri $uri/ /index.php?$query_string;
    '';
  };

  locations."= /favicon.ico" = {
    extraConfig = ''
      access_log off;
      log_not_found off;
    '';
  };
  locations."= /robots.txt" = {
    extraConfig = ''
      access_log off;
      log_not_found off;
    '';
  };

  locations."~ \\.php$" = {
    extraConfig = ''
      fastcgi_pass unix:${config.services.phpfpm.pools.php82.socket};
      fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
      include ${config.services.nginx.package}/conf/fastcgi_params;
      # include ${config.services.nginx.package}/conf/fastcgi.conf;
      # fastcgi_index index.php;
    '';
  };

  locations."~ /\\.(?!well-known).*" = {
    extraConfig = ''
      deny all;
    '';
  };
}
