{
  config,
  lib,
  pkgs,
  ...
}:

let
  # fontFamily = "JetBrainsMono Nerd Font Mono";
  # fontFamily = "MonaspaceAr Nerd Font Mono";
  # fontFamily = "Monaspace Argon NF";
  fontFamily = "Monaspace Krypton NF";
  fontSize = 10;
in
{
  home.packages = with pkgs; [
    ngrok
  ];

  programs.alacritty.enable = true;
  programs.alacritty.settings.colors.bright = {
    black = "#4e4e4e";
    blue = "#82aaff";
    cyan = "#89ddff";
    green = "#c3e88d";
    magenta = "#f07178";
    red = "#ff5370";
    white = "#ffffff";
    yellow = "#ffcb6b";
  };
  programs.alacritty.settings.colors.normal = {
    black = "#000000";
    blue = "#6182b8";
    cyan = "#39adb5";
    green = "#91b859";
    magenta = "#ff5370";
    red = "#e53935";
    white = "#a0a0a0";
    yellow = "#ffb62c";
  };
  programs.alacritty.settings.colors.primary = {
    background = "#263238";
    foreground = "#eeffff";
  };
  programs.alacritty.settings.colors.cursor = {
    text = "#263238";
    cursor = "#eeffff";
  };
  programs.alacritty.settings.font.size = fontSize;
  programs.alacritty.settings.font.bold = {
    family = fontFamily;
    style = "Bold";
  };
  programs.alacritty.settings.font.bold_italic = {
    family = fontFamily;
    style = "Bold Italic";
  };
  programs.alacritty.settings.font.italic = {
    family = fontFamily;
    style = "Italic";
  };
  programs.alacritty.settings.font.normal = {
    family = fontFamily;
    style = "Regular";
  };
  programs.alacritty.settings.cursor.style = {
    shape = "Beam";
    blinking = "Off";
  };

  programs.starship.enable = true;
  programs.starship.enableZshIntegration = true;
  programs.starship.settings = { };

  programs.ripgrep.enable = true;
  programs.ripgrep.arguments = [ ];

  programs.zoxide.enable = true;
  programs.zoxide.enableZshIntegration = true;
  programs.zoxide.options = [ ];

  programs.eza.enable = true;
  programs.eza.enableZshIntegration = true;
  programs.eza.git = true;
  programs.eza.colors = "auto";
  programs.eza.icons = "auto";

  programs.bat.enable = true;
  programs.bat.config = { };

  programs.fd.enable = true;
  programs.fd.hidden = false;
  programs.fd.ignores = [ ];
  programs.fd.extraOptions = [ ];

  programs.fzf.enable = true;
  programs.fzf.enableZshIntegration = true;
  programs.fzf.tmux.enableShellIntegration = true;

  programs.mcfly.enable = true;
  programs.mcfly.fuzzySearchFactor = 2;
  programs.mcfly.fzf.enable = true;
  programs.mcfly.interfaceView = "BOTTOM";

  programs.htop.enable = true;

  programs.jq.enable = true;
}
