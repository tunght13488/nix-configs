# ngrok — managed tunnel config; authtoken injected from agenix secret
{ config, ... }:
{
  programs.ngrok = {
    enable = true;
    authtokenFile = config.age.secrets.ngrok-authtoken.path;
    endpoints = {
      middleware = {
        name = "middleware";
        url = "https://inherently-good-tarpon.ngrok-free.app";
        upstream.url = "middleware.vm.local:443";
      };
    };
  };
}
