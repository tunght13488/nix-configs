{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.zsh = {
    enable = true;
    shellAliases = {
      grep = "rg";
      tf = "terraform";
      ls = "eza --group-directories-first";
      l = "ls -l";
      la = "l -a";
      cat = "bat --paging=never --style=plain";
      find = "fd";
      du = "ncdu --color dark -rr -x --exclude .git --exclude node_modules";

      a = "php artisan";
      c = "composer";
      mx = "chmod a+x";
      hosts = "sudo $EDITOR /etc/hosts";
      sshconfig = "$EDITOR ~/.ssh/config";
      myip = "dig +short myip.opendns.com @resolver1.opendns.com";
      myips = "ifconfig -a | perl -nle'/(\d+.\d+.\d+.\d+)/ && print $1'";
      fs = "stat -f \"%z bytes\"";
    };
  };

  programs.zsh.prezto = {
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
}
