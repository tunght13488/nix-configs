{ pkgs
, ...
}:

{
  programs.tmux = {
    enable = true;
    prefix = "`";
    baseIndex = 1;
    keyMode = "vi";
    escapeTime = 0;
    focusEvents = true;
    historyLimit = 10000;
    clock24 = true;
    # sensibleOnTop = true;
    extraConfig = ''
      # extra config
      bind-key C-a set-option -g prefix C-a
      bind-key C-b set-option -g prefix `
      bind-key r source-file ~/.config/tmux/tmux.conf
      # bind-key j command-prompt -p "join pane from:"  "join-pane -s '%%'"
      # bind-key s command-prompt -p "send pane to:"  "join-pane -t '%%'"
      set -g repeat-time 125
      set-window-option -g automatic-rename on
      set -g set-titles on
      set -g set-titles-string '#S:#I.#P #W'
      setw -g monitor-activity on
      set -g visual-activity on
      set -g window-style 'bg=colour238'
      set -g window-active-style 'bg=colour235'
      setw -g clock-mode-colour colour250
      run-shell "powerline-daemon -q"
      source "${pkgs.python313Packages.powerline}/share/tmux/powerline.conf"
      set -g update-environment "DISPLAY SSH_ASKPASS SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY"
    '';
    plugins = with pkgs; [
      tmuxPlugins.sensible
      tmuxPlugins.pain-control
      tmuxPlugins.prefix-highlight
      tmuxPlugins.copycat
      {
        plugin = tmuxPlugins.yank;
        extraConfig = "set -g @yank_selection 'clipboard'";
      }
      tmuxPlugins.cpu
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = "set -g @continuum-restore 'on'";
      }
      tmuxPlugins.vim-tmux-navigator
      {
        plugin = tmuxPlugins.fingers;
        extraConfig = ''
          set -g @fingers-key H
        '';
      }
      tmuxPlugins.tmux-fzf
    ];
  };
  home.packages = with pkgs; [
    tmux
    python313
    python313Packages.powerline
  ];
}
