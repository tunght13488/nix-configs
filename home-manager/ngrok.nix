# ngrok — managed tunnel config; authtoken injected from agenix secret
{ config, pkgs, ... }:
{
  programs.ngrok = {
    enable = true;
    package = pkgs.unstable.ngrok;
    authtokenFile = config.age.secrets.ngrok-authtoken.path;
    settings.agent.web_addr = "0.0.0.0:4040";
    endpoints = {
      middleware = {
        name = "middleware";
        url = "https://inherently-good-tarpon.ngrok-free.app";
        upstream.url = "middleware.vm.local:80";
        traffic_policy.on_http_request = [
          {
            actions = [
              {
                type = "add-headers";
                config.headers.host = "middleware.vm.local";
              }
            ];
          }
        ];
      };
      prbot = {
        name = "prbot";
        url = "https://inherently-good-tarpon.ngrok-free.app";
        upstream.url = "prbot.vm.local:80";
        traffic_policy.on_http_request = [
          {
            actions = [
              {
                type = "add-headers";
                config.headers.host = "prbot.vm.local";
              }
            ];
          }
        ];
      };
    };
  };
}
