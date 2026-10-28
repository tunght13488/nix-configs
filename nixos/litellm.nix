# nixos/litellm.nix — native LiteLLM gateway
#
# Hosts LiteLLM as a NixOS service on loopback, behind the existing
# `litellm.vm.local` nginx vhost (nixos/vhosts/litellm.vm.local.nix), with state
# in the local PostgreSQL instance (nixos/postgres.nix).
#
# Models are NOT declared here: `store_model_in_db` makes PostgreSQL the source
# of truth, so models and provider credentials are added through the Admin UI at
# https://litellm.vm.local/ui and survive restarts and rebuilds.
#
# Secrets (LITELLM_MASTER_KEY, LITELLM_SALT_KEY) come from the agenix-managed
# environment file (nixos/agenix.nix); decrypt with
# `cd secrets && agenix -d litellm-env.age -i ~/.ssh/ssh_agenix`. The salt key
# encrypts provider credentials at rest — never change it once models exist.
#
# Prisma: LiteLLM's schema bootstrap needs a Prisma 5.17.0 CLI and the Python
# client generated from LiteLLM's own schema. Both come from pkgs/prisma_5.nix,
# pkgs/prisma-engines_5.nix and pkgs/prisma_5-litellm_schema.nix (wired into
# `pkgs.litellm` by overlays/default.nix); do not remove them.
{ config, lib, pkgs, ... }:

let
  # LiteLLM shells out to this CLI for `prisma db push` on startup.
  prismaCli = pkgs.prisma_5;
in
{
  services.litellm = {
    enable = true;

    # Loopback only; nginx terminates TLS and proxies to this port.
    host = "127.0.0.1";
    port = 4001;

    # Master key and credential-encryption salt. Defaults to the agenix secret;
    # the VM test overrides it with a plain file so it needs no age identity.
    environmentFile = lib.mkDefault config.age.secrets.litellm-env.path;

    settings = {
      # Intentionally empty: models live in PostgreSQL (Admin UI).
      model_list = [ ];

      general_settings.store_model_in_db = true;
    };

    environment = {
      # Password-free: services.postgresql trusts the litellm role on loopback.
      DATABASE_URL = "postgresql://litellm@127.0.0.1:5432/litellm";

      # DynamicUser has no home, so anything resolving Path.home() would land on
      # `/` (read-only). StateDirectory owns this path.
      HOME = "/var/lib/litellm";

      # Schema setup must not fail silently: without the tables the Admin UI and
      # every database-backed endpoint are broken.
      ENFORCE_PRISMA_MIGRATION_CHECK = "true";

      # The Python Prisma client starts this query engine directly.
      PRISMA_QUERY_ENGINE_BINARY = "${pkgs.prisma-engines_5}/bin/query-engine";
    };
  };

  systemd.services.litellm = {
    # `prisma` (schema push on startup) is a Node CLI. `openssl` is not used by
    # anything we run directly, but prisma-client-py probes it (`openssl version
    # -v`) to derive its binary-platform string; without it the Python client
    # raises FileNotFoundError, which LiteLLM swallows as "Not connected to the
    # query engine".
    path = [
      prismaCli
      pkgs.nodejs
      (lib.getBin pkgs.openssl)
    ];

    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
  };
}
