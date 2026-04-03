{
  config,
  lib,
  pkgs,
  ...
}:

let
  # fontFamily = "JetBrainsMono Nerd Font Mono";
  # fontFamily = "MonaspaceAr Nerd Font Mono";
  fontFamily = "Monaspace Argon NF";
  fontSize = 10;
in
{
  programs.alacritty = {
    enable = true;
    settings = {
      colors = {
        bright = {
          black = "#4e4e4e";
          blue = "#82aaff";
          cyan = "#89ddff";
          green = "#c3e88d";
          magenta = "#f07178";
          red = "#ff5370";
          white = "#ffffff";
          yellow = "#ffcb6b";
        };
        normal = {
          black = "#000000";
          blue = "#6182b8";
          cyan = "#39adb5";
          green = "#91b859";
          magenta = "#ff5370";
          red = "#e53935";
          white = "#a0a0a0";
          yellow = "#ffb62c";
        };
        primary = {
          background = "#263238";
          foreground = "#eeffff";
        };
        cursor = {
          text = "#263238";
          cursor = "#eeffff";
        };
      };
      font = {
        size = fontSize;
        bold = {
          family = fontFamily;
          style = "Bold";
        };
        bold_italic = {
          family = fontFamily;
          style = "Bold Italic";
        };
        italic = {
          family = fontFamily;
          style = "Italic";
        };
        normal = {
          family = fontFamily;
          style = "Regular";
        };
      };
      cursor = {
        style = {
          shape = "Beam";
          blinking = "Off";
        };
      };
    };
    # theme = null;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = { };
  };

  programs.ripgrep = {
    enable = true;
    arguments = [ ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ ];
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    colors = "auto";
    icons = "auto";
    extraOptions = [ ];
    theme = { };
  };

  programs.bat = {
    enable = true;
    config = { };
    syntaxes = { };
    themes = { };
    extraPackages = with pkgs.bat-extras; [
      # batdiff
      # batman
      # batgrep
      # batwatch
    ];
  };

  programs.fd = {
    enable = true;
    hidden = false;
    ignores = [ ];
    extraOptions = [ ];
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    tmux.enableShellIntegration = true;
    # changeDirWidgetCommand = null;
    # changeDirWidgetOptions = [ ];
    # colors = { };
    # defaultCommand = null;
  };

  programs.mcfly = {
    enable = true;
    fuzzySearchFactor = 2;
    fzf.enable = true;
    interfaceView = "BOTTOM";
    # keyScheme = "vim";
    # settings = { };
  };
}
