{ lib
, ...
}:

{
  programs.ssh.enableDefaultConfig = false;
  programs.ssh.enable = true;
  programs.ssh.matchBlocks = {
    "*" = {
      forwardAgent = true;
      # identityAgent = [ "~/.1password/agent.sock" ];
    };
  }
  // {
    # GitHub SSH for work and personal accounts
    "github.com" = lib.hm.dag.entryBefore [ "*" ] {
      hostname = "github.com";
      user = "git";
      identityFile = [ "~/.ssh/ssh_sl" ];
      identitiesOnly = true;
    };

    "github.me" = lib.hm.dag.entryBefore [ "*" ] {
      hostname = "github.com";
      user = "git";
      identityFile = [ "~/.ssh/ssh_tunght13488" ];
      identitiesOnly = true;
    };
  }
  // {
    # SL SSH over AWS SSM
    "sl.*" = lib.hm.dag.entryBefore [ "*" ] {
      proxyCommand = "sh -c \"aws --profile sl-dev ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'\"";
      user = "ubuntu";
    };

    "sl.nat" = lib.hm.dag.entryBefore [ "sl.*" ] {
      hostname = "i-0650466c4a7d0df4c";
    };

    "sl.hrbot" = lib.hm.dag.entryBefore [ "sl.*" ] {
      hostname = "i-07a2b716eaa1111e0";
    };

    "sl.couchdb" = lib.hm.dag.entryBefore [ "sl.*" ] {
      hostname = "i-0ba7ffc824ac53419";
    };

    "sl.prbot.prd" = lib.hm.dag.entryBefore [ "sl.*" ] {
      hostname = "i-0a38ce66657ceaa58";
    };

    "sl.prbot.stg" = lib.hm.dag.entryBefore [ "sl.*" ] {
      hostname = "i-0b17e8b6b162c4433";
    };

    "sl.blog" = lib.hm.dag.entryBefore [ "sl.*" ] {
      hostname = "i-0c6830c7a5526dd5e";
    };

    "sl.middleware.stg" = lib.hm.dag.entryBefore [ "sl.*" ] {
      hostname = "i-00eec811b2bbd3c9f";
    };

    "sl.middleware.prd" = lib.hm.dag.entryBefore [ "sl.*" ] {
      hostname = "i-02637399b1339502d";
    };

    "sl.v3.prd" = lib.hm.dag.entryBefore [ "sl.*" ] {
      hostname = "i-03bc27fc294c90763";
    };

    "sl.v3.stg" = lib.hm.dag.entryBefore [ "sl.*" ] {
      hostname = "i-0e71c4191b4d7bf8c";
    };
  }
  // {
    # SL SSH over public IP
    "sl-*" = lib.hm.dag.entryBefore [ "*" ] {
      user = "ubuntu";
      identityFile = [ "~/.ssh/ssh_sl" ];
      identitiesOnly = true;
    };

    "sl-pim-dev" = lib.hm.dag.entryBefore [ "sl-*" ] {
      hostname = "13.214.185.191";
      user = "admin";
    };

    "sl-pim-prd" = lib.hm.dag.entryBefore [ "sl-*" ] {
      hostname = "122.248.254.252";
      user = "admin";
    };

    "sl-pim-new-dev" = lib.hm.dag.entryBefore [ "sl-*" ] {
      hostname = "54.169.2.223";
      user = "admin";
    };

    "sl-pim-new-prd" = lib.hm.dag.entryBefore [ "sl-*" ] {
      hostname = "13.213.12.138";
      user = "admin";
    };

  };
  services.ssh-agent.enable = true;
  # services.ssh-agent.enableZshIntegration = true;
}
