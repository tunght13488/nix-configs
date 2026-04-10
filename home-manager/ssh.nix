{ config, pkgs, ... }:

{
  programs.ssh.enableDefaultConfig = false;
  programs.ssh.enable = true;
  programs.ssh.matchBlocks = {
    "github.com" = {
      hostname = "github.com";
      user = "git";
      identityFile = [ "~/.ssh/ssh_sl" ];
      identitiesOnly = true;
    };

    "github.me" = {
      hostname = "github.com";
      user = "git";
      identityFile = [ "~/.ssh/ssh_tunght13488" ];
      identitiesOnly = true;
    };

    "*" = {
      forwardAgent = true;
      identityAgent = [ "~/.1password/agent.sock" ];
    };
  };
  services.ssh-agent.enable = true;
  # services.ssh-agent.enableZshIntegration = true;
}
