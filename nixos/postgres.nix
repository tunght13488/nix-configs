# nixos/postgres.nix — local PostgreSQL server for LiteLLM
#
# LiteLLM's Prisma schema targets PostgreSQL, so it cannot reuse the MySQL
# service used by the local PHP stack.
#
# Scope is deliberately narrow:
#   - one database (`litellm`) owned by one role (`litellm`), no superuser
#     clauses
#   - `enableTCPIP` stays false, so listen_addresses = "localhost": the server
#     binds 127.0.0.1 and ::1 only
#   - trust authentication is granted for that role/database over loopback
#     only; the module's md5 defaults remain for everything else
{ pkgs, ... }:
{
  services.postgresql = {
    enable = true;

    # Deliberately newer than the stateVersion default (17): the module would
    # otherwise switch majors on a stateVersion bump. Changing this again is a
    # major-version upgrade and needs pg_upgrade.
    package = pkgs.postgresql_18;

    ensureDatabases = [ "litellm" ];

    ensureUsers = [
      {
        name = "litellm";
        ensureDBOwnership = true;
      }
    ];

    # Inserted above the module's md5 defaults (see the `authentication`
    # option: added rules go first). Only the LiteLLM role connecting to the
    # LiteLLM database over loopback skips password authentication.
    authentication = ''
      host litellm litellm 127.0.0.1/32 trust
      host litellm litellm ::1/128 trust
    '';
  };
}
