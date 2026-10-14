{ pkgs, ... }: {
  home.packages = with pkgs; [
    go
  ];
  home.sessionPath = [
    "$HOME/go/bin"
  ];
}
