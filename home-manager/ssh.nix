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

    "sl.nat" = {
      hostname = "i-0650466c4a7d0df4c";
    };

    "sl.hrbot" = {
      hostname = "i-07a2b716eaa1111e0";
    };

    "sl.couchdb" = {
      hostname = "i-0ba7ffc824ac53419";
    };

    "sl.prbot.prd" = {
      hostname = "i-0a38ce66657ceaa58";
    };

    "sl.prbot.stg" = {
      hostname = "i-0b17e8b6b162c4433";
    };

    "sl.blog" = {
      hostname = "i-0c6830c7a5526dd5e";
    };

    "sl.middleware.stg" = {
      hostname = "i-00eec811b2bbd3c9f";
    };

    "sl.middleware.prd" = {
      hostname = "i-02637399b1339502d";
    };

    "sl.v3.prd" = {
      hostname = "i-03bc27fc294c90763";
    };

    "sl.v3.stg" = {
      hostname = "i-0e71c4191b4d7bf8c";
    };

    "sl.*" = {
      proxyCommand = "sh -c \"aws --profile sl-dev ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'\"";
      user = "ubuntu";
    };

    "*" = {
      forwardAgent = true;
      # identityAgent = [ "~/.1password/agent.sock" ];
    };
  };
  services.ssh-agent.enable = true;
  # services.ssh-agent.enableZshIntegration = true;
}
