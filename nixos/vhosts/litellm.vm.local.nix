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

    # LiteLLM's realtime endpoint upgrades to a websocket; this also sets
    # proxy_http_version 1.1 plus the Connection/Upgrade headers.
    proxyWebsockets = true;

    extraConfig = ''
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;

      # Streamed completions arrive token by token, and long generations can
      # pause well past nginx's 60s default. Buffer-free delivery plus generous
      # read/send timeouts keep SSE responses flowing and alive.
      proxy_buffering off;
      proxy_read_timeout 600s;
      proxy_send_timeout 600s;
    '';
  };
}
