{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.mcfly = {
    enable = true;
    fuzzySearchFactor = 2;
    # fzf.enable = true;
    interfaceView = "BOTTOM";
    # keyScheme = "vim";
    # settings = { };
  };
}
