{ ... }: {
  home = {
    # Declaratively configure .npmrc
    file = {
      ".npmrc".text = ''
        prefix=/home/tung/.npm-global
      '';
    };

    # Add the global bin directory to your PATH
    sessionPath = [
      "$HOME/.npm-global/bin"
    ];
  };
}
