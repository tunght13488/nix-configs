# This is just an example, you should generate yours with nixos-generate-config and put it in here.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.mysql = {
    enable = true;
    package = pkgs.mysql80;
    # settings = { };
  };
}
