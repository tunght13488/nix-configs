{ pkgs, ... }:
let
  mkcertStateDir = "/var/lib/mkcert";
  certDir = "/var/lib/local-certs";
  certFile = "${certDir}/vm.local.pem";
  keyFile = "${certDir}/vm.local-key.pem";
in
{
  users.groups.mkcert.members = [ "tung" ];

  services.resolved = {
    enable = true;
    domains = [ "~vm.local" ];
  };

  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    settings = {
      bind-interfaces = true;
      listen-address = "127.0.0.1";
      address = [ "/vm.local/127.0.0.1" ];
    };
  };

  environment.systemPackages = with pkgs; [
    mkcert
    nssTools
  ];

  systemd.tmpfiles.rules = [
    "d ${mkcertStateDir} 0750 root mkcert -"
    "d ${certDir} 0750 root nginx -"
  ];

  systemd.services.mkcert-vm-local = {
    description = "Generate local mkcert certificate for vm.local hosts";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    before = [ "nginx.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu

      export CAROOT=${mkcertStateDir}

      mkdir -p "$CAROOT" ${certDir}

      ${pkgs.mkcert}/bin/mkcert \
        -cert-file ${certFile} \
        -key-file ${keyFile} \
        vm.local \
        '*.vm.local' \
        localhost \
        127.0.0.1 \
        ::1

      chown root:mkcert "$CAROOT" "$CAROOT/rootCA.pem" "$CAROOT/rootCA-key.pem"
      chmod 0750 "$CAROOT"
      chmod 0644 "$CAROOT/rootCA.pem"
      chmod 0640 "$CAROOT/rootCA-key.pem"

      chmod 0644 ${certFile}
      chown root:nginx ${certFile} ${keyFile}
      chmod 0640 ${keyFile}
    '';
  };

  systemd.services.nginx = {
    wants = [ "mkcert-vm-local.service" ];
    after = [ "mkcert-vm-local.service" ];
  };
}
