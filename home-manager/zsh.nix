{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.zsh = {
    enable = true;
    prezto = {
      enable = true;
      caseSensitive = false;
      color = true;
      pmodules = [
        "environment"
        "terminal"
        "editor"
        "history"
        "directory"
        "spectrum"
        "utility"
        "completion"
        "archive"
        "command-not-found"
        "dpkg"
        "pacman"
        "fasd"
        "git"
        "ruby"
        "homebrew"
        "docker"
        # "explain"
        "node"
        "osx"
        "yum"
        "ssh"
        "tmux"
        "syntax-highlighting"
        "history-substring-search"
        # "fzf"
        # "contrib-prompt"
        "prompt"
      ];
      editor = {
        keymap = "vi";
        dotExpansion = true;
        promptContext = true;
      };
      ssh.identities = [
        "ssh_sl"
        "ssh_tunght13488"
      ];
      syntaxHighlighting = {
        highlighters = [
          "main"
          "brackets"
          "pattern"
          "line"
          "cursor"
          "root"
        ];
        styles = {
          builtin = "bg=blue";
          command = "bg=blue";
          function = "bg=blue";
        };
        pattern = {
          "rm*-rf*" = "fg=white,bold,bg=red";
        };
      };
      terminal = {
        autoTitle = true;
        windowTitleFormat = "%n@%m: %s";
        tabTitleFormat = "%m: %s";
      };
    };
  };
}
