{ lib
, ...
}:

{
  programs.ssh.enableDefaultConfig = false;
  programs.ssh.enable = true;
  programs.ssh.settings = {
    "*" = {
      # ForwardAgent = true;
      # IdentityAgent = [ "~/.1password/agent.sock" ];
    };
  }
  // {
    # GitHub SSH for work and personal accounts
    "github.com" = lib.hm.dag.entryBefore [ "*" ] {
      HostName = "github.com";
      User = "git";
      IdentityFile = [ "~/.ssh/ssh_sl" ];
      IdentitiesOnly = true;
    };

    "github.me" = lib.hm.dag.entryBefore [ "*" ] {
      HostName = "github.com";
      User = "git";
      IdentityFile = [ "~/.ssh/ssh_tunght13488" ];
      IdentitiesOnly = true;
    };
  }
  // {
    # SL SSH over AWS SSM
    "sl.*" = lib.hm.dag.entryBefore [ "*" ] {
      ProxyCommand = "sh -c \"aws --profile sl-dev ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'\"";
      User = "ubuntu";
    };

    "sl.nat" = lib.hm.dag.entryBefore [ "sl.*" ] {
      HostName = "i-0650466c4a7d0df4c";
    };

    "sl.hrbot" = lib.hm.dag.entryBefore [ "sl.*" ] {
      HostName = "i-04c51e46906e296a5";
    };

    "sl.couchdb" = lib.hm.dag.entryBefore [ "sl.*" ] {
      HostName = "i-0ba7ffc824ac53419";
    };

    "sl.prbot.prd" = lib.hm.dag.entryBefore [ "sl.*" ] {
      HostName = "i-09bd2b88ce03daf6c";
    };

    "sl.prbot.stg" = lib.hm.dag.entryBefore [ "sl.*" ] {
      HostName = "i-0b17e8b6b162c4433";
    };

    "sl.blog" = lib.hm.dag.entryBefore [ "sl.*" ] {
      HostName = "i-0c6830c7a5526dd5e";
    };

    "sl.middleware.stg" = lib.hm.dag.entryBefore [ "sl.*" ] {
      HostName = "i-00eec811b2bbd3c9f";
    };

    "sl.middleware.prd-old" = lib.hm.dag.entryBefore [ "sl.*" ] {
      HostName = "i-02637399b1339502d";
    };

    "sl.middleware.prd" = lib.hm.dag.entryBefore [ "sl.*" ] {
      HostName = "i-0ac7915f0910cfee7";
    };

    "sl.v3.prd" = lib.hm.dag.entryBefore [ "sl.*" ] {
      HostName = "i-03bc27fc294c90763";
    };

    "sl.v3.stg" = lib.hm.dag.entryBefore [ "sl.*" ] {
      HostName = "i-0e71c4191b4d7bf8c";
    };

    "sl.pimcore.dev-2026" = lib.hm.dag.entryBefore [ "sl.*" ] {
      HostName = "i-0751b7f169cd79023";
    };
  }
  // {
    # SL SSH over public IP
    "sl-*" = lib.hm.dag.entryBefore [ "*" ] {
      User = "ubuntu";
      IdentityFile = [ "~/.ssh/ssh_sl" ];
      IdentitiesOnly = true;
    };

    "sl-pim-dev" = lib.hm.dag.entryBefore [ "sl-*" ] {
      HostName = "13.214.185.191";
      User = "admin";
    };

    "sl-pim-prd" = lib.hm.dag.entryBefore [ "sl-*" ] {
      HostName = "122.248.254.252";
      User = "admin";
    };

    "sl-pim-new-dev" = lib.hm.dag.entryBefore [ "sl-*" ] {
      HostName = "54.169.2.223";
      User = "admin";
    };

    "sl-pim-new-prd" = lib.hm.dag.entryBefore [ "sl-*" ] {
      HostName = "13.213.12.138";
      User = "admin";
    };

  };
  services.ssh-agent.enable = true;
  # services.ssh-agent.enableZshIntegration = true;
}
