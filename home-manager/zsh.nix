{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.zsh.enable = true;
  programs.zsh.shellAliases = {
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
  programs.zsh.initContent =
    let
      zshConfigEarlyInit = lib.mkOrder 500 "# order 500";
      zshConfigBeforeCompInit = lib.mkOrder 550 "# order 550";
      zshConfig = lib.mkOrder 1000 "# order 1000";
      zshConfigAfter = lib.mkOrder 1500 ''
        if (( $+commands[op])); then
          eval "$(op completion zsh)"; compdef _op op
        fi
        if (( $+commands[ngrok])); then
          eval "$(ngrok completion)";
        fi
      '';
    in
    lib.mkMerge [
      zshConfigEarlyInit
      zshConfigBeforeCompInit
      zshConfig
      zshConfigAfter
    ];

  programs.zsh.prezto.enable = true;
  programs.zsh.prezto.caseSensitive = false;
  programs.zsh.prezto.color = true;
  programs.zsh.prezto.pmodules = [
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
  programs.zsh.prezto.editor.keymap = "vi";
  programs.zsh.prezto.editor.dotExpansion = true;
  programs.zsh.prezto.editor.promptContext = true;
  programs.zsh.prezto.ssh.identities = [
    "ssh_sl"
    "ssh_tunght13488"
  ];
  programs.zsh.prezto.syntaxHighlighting.highlighters = [
    "main"
    "brackets"
    "pattern"
    "line"
    "cursor"
    "root"
  ];
  programs.zsh.prezto.syntaxHighlighting.styles.builtin = "bg=blue";
  programs.zsh.prezto.syntaxHighlighting.styles.command = "bg=blue";
  programs.zsh.prezto.syntaxHighlighting.styles.function = "bg=blue";
  programs.zsh.prezto.syntaxHighlighting.pattern = {
    "rm*-rf*" = "fg=white,bold,bg=red";
  };
  programs.zsh.prezto.terminal.autoTitle = true;
  programs.zsh.prezto.terminal.windowTitleFormat = "%n@%m: %s";
  programs.zsh.prezto.terminal.tabTitleFormat = "%m: %s";
  programs.zsh.prezto.tmux.autoStartLocal = true;
  programs.zsh.prezto.tmux.autoStartRemote = true;
}
