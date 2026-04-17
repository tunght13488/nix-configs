# nixos/nginx.nix — system nginx service
#
# Each virtual host is a separate file under ./vhosts/.
# nginx runs as the `nginx` user; it can read files under /home/tung/php-sites/
# because that directory (and its subdirs) are group-readable by `nginx`.
# The site index.php files are provisioned by home-manager/home.nix via home.file.
#
# ── How to add a new virtual host ──────────────────────────────────────────────
# 1. Copy nixos/vhosts/php81.vm.local.nix → nixos/vhosts/<yoursite>.vm.local.nix
#    and update serverName, root, and fastcgi_pass (pool socket).
# 2. Add a matching pool in nixos/php-fpm.nix.
# 3. Add the new file to the `vhosts` list below.
# 4. Add a home.file entry for the site root in home-manager/home.nix.
# 5. Run: sudo nixos-rebuild switch --flake '.#nixos-vmware'
# ───────────────────────────────────────────────────────────────────────────────
{ config, lib, ... }:

let
  localDevCert = "/var/lib/local-certs/vm.local.pem";
  localDevKey = "/var/lib/local-certs/vm.local-key.pem";

  localDevTls = {
    forceSSL = true;
    sslCertificate = localDevCert;
    sslCertificateKey = localDevKey;
  };

  # List every vhost file here.  Each file receives { config, lib, pkgs, ... }
  # and must return an attrset that is valid as a services.nginx.virtualHosts value.
  vhostFiles = [
    ./vhosts/php81.vm.local.nix
    ./vhosts/php82.vm.local.nix
    ./vhosts/php83.vm.local.nix
    ./vhosts/middleware.vm.local.nix
    ./vhosts/v3.vm.local.nix
  ];

  # Turn a file path into { name = serverName; value = <vhost attrset>; }.
  # The file is imported and called with the current module args so it can
  # reference config.services.phpfpm.pools.*.socket.
  loadVhost =
    file:
    let
      vhost = (import file) { inherit config lib; };
    in
    lib.nameValuePair vhost.serverName ((builtins.removeAttrs vhost [ "serverName" ]) // localDevTls);
in
{
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    virtualHosts = builtins.listToAttrs (map loadVhost vhostFiles);
  };

  # Allow nginx to read site files that live under /home/tung/php-sites/.
  # NixOS's nginx module sets ProtectHome=true by default, which makes /home
  # invisible to the nginx process.  Override that for the php-sites subtree
  # while keeping everything else locked down.
  systemd.services.nginx.serviceConfig = {
    ProtectHome = "read-only";
  };

  # Open HTTP + HTTPS for local dev sites.
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
