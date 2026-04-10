{ config, ... }:
{
  serverName = "v3.vm.local";
  root = "/home/tung/code/admin_ci3/public";
  extraConfig = ''
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    index index.php;
    charset utf-8;
    error_page 404 /index.php;
    error_log /var/log/nginx/v3.vm.local_error.log;
    access_log /var/log/nginx/v3.vm.local_access.log;
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
      fastcgi_pass unix:${config.services.phpfpm.pools.php83.socket};
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
