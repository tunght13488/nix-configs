{ ... }:
{
  serverName = "litellm.vm.local";
  extraConfig = ''
    charset utf-8;
    error_log /var/log/nginx/litellm.vm.local_error.log;
    access_log /var/log/nginx/litellm.vm.local_access.log;
  '';

  locations."/" = {
    proxyPass = "http://127.0.0.1:4001";
    extraConfig = ''
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    '';
  };
}
