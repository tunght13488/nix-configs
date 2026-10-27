# Design

## Context

See [proposal.md](proposal.md) for motivation and [specs/litellm-gateway/spec.md](specs/litellm-gateway/spec.md) for the behavior contract.

The existing `nixos/nginx.nix` already loads `nixos/vhosts/litellm.vm.local.nix`; that vhost has the local TLS configuration applied centrally and forwards to `127.0.0.1:4001`. It currently preserves forwarded headers but does not set streaming-specific buffering or timeout behavior. `nixos/configuration.nix` imports the MySQL module, but not PostgreSQL or LiteLLM. Agenix is currently wired into Home Manager only.

The pinned nixpkgs release provides `services.litellm`, including a hardened systemd service, a settings file, an environment-file option, and writable state directories. The module defaults to port 8080, so it must be configured to match the existing nginx upstream. LiteLLM's Prisma schema uses PostgreSQL, not the existing MySQL service.

A database-enabled LiteLLM startup attempts Prisma schema setup. The Python Prisma client can lazily install its npm CLI and engines, while the NixOS service module does not itself provide a pre-populated Prisma cache or Node runtime. That runtime dependency must be handled declaratively; otherwise first startup may rely on a mutable network download or leave the database schema unavailable.

## Goals / Non-Goals

**Goals:**
- Reuse the packaged NixOS LiteLLM module and the existing local HTTPS vhost.
- Keep LiteLLM and PostgreSQL listeners on loopback; keep PostgreSQL trust authentication limited to loopback and the dedicated LiteLLM database role.
- Make PostgreSQL-backed model management available in the Admin UI without an initial static model list.
- Keep admin and credential-encryption secrets out of the Nix store, and make Prisma schema setup reliable at service startup.

**Non-Goals:**
- Publish LiteLLM or PostgreSQL directly to the network or introduce a public DNS/TLS endpoint.
- Define provider models or credentials in Nix at initial deployment.
- Replace or reconfigure the existing MySQL-backed development stack.
- Add multi-instance coordination, Redis, or a separate database backup service.

## Decisions

1. **Use the nixpkgs `services.litellm` module.** It already supplies the service lifecycle, state directories, UI runtime path, and systemd hardening. Configure its host as loopback and port 4001 to preserve the existing vhost upstream. A hand-written service or Docker Compose would duplicate module behavior and work against the native-hosting goal.

2. **Use a dedicated local PostgreSQL database and role.** LiteLLM's Prisma schema is PostgreSQL-specific, so the existing MySQL service cannot be reused. Bind PostgreSQL to loopback and permit trust authentication only for loopback connections to the LiteLLM database. The connection URL therefore needs no database password. This retains the user's requested setup while limiting the role to LiteLLM's database.

3. **Use PostgreSQL as the source of truth for models and provider credentials.** Enable `general_settings.store_model_in_db` and leave the Nix-managed model list empty. Administrators can add models later in the UI; infrastructure settings remain declarative in Nix. Do not manage the same model deployments in both Nix configuration and the UI.

4. **Use NixOS agenix for runtime secrets.** Wire the existing agenix input into the NixOS module set, configure the NixOS identity path to use the existing `/home/tung/.ssh/ssh_agenix` key, and provide `LITELLM_MASTER_KEY` and a stable `LITELLM_SALT_KEY` through an encrypted environment file. Reference the master key from LiteLLM configuration as an environment variable; never interpolate secret values into generated YAML or systemd units. Provider credentials entered in the UI are stored in PostgreSQL encrypted with the stable salt. Verify that the system agenix service can read the identity key at boot.

5. **Package the Prisma CLI runtime instead of installing it at service startup.** Add Node and a Nix-built Prisma CLI/engine cache matching the Prisma client version used by the pinned LiteLLM package, and point the service at that cache. Enable LiteLLM's migration-failure enforcement so schema setup errors fail the service instead of being hidden behind a running but unusable Admin UI. Verify this against the actual package during implementation before relying on it.

6. **Extend the existing nginx location for streaming.** Keep the current forwarded headers and upstream, disable proxy response buffering, and use long read/send timeouts appropriate for streamed model responses. Do not open the backend or database ports in the firewall.

## Risks / Trade-offs

- **Loopback trust allows any local process to authenticate as the LiteLLM database role** → Keep PostgreSQL bound to loopback, grant ownership only on the dedicated LiteLLM database, and do not grant the role elevated PostgreSQL privileges.
- **LiteLLM's migration recovery path can run `prisma db push --accept-data-loss`** → Back up PostgreSQL before LiteLLM upgrades; a NixOS generation rollback alone does not restore database contents.
- **Changing the credential-encryption salt can make UI-stored provider credentials unreadable** → Keep the salt stable, protect it with agenix, and back it up with the encrypted secret.
- **A mismatched or missing Prisma CLI/engine cache prevents database initialization** → Pin the runtime to the Python Prisma client's expected CLI/engine version and verify a clean first start with PostgreSQL in an integration test.
- **The API has no usable model immediately after deployment** → This is intentional; add the first provider and model through the Admin UI before sending completion requests.

## Migration Plan

1. Build and evaluate the NixOS configuration, including the pinned Prisma runtime and the database migration path.
2. Before activation, stop any existing Compose/container instance using port 4001 and take a PostgreSQL backup if the database already contains LiteLLM data.
3. Deploy PostgreSQL, LiteLLM, agenix secrets, and the updated nginx vhost. Systemd ordering must start PostgreSQL before LiteLLM; schema initialization must complete before LiteLLM is considered ready.
4. Verify the service, HTTPS Admin UI, API health, and streamed responses. Add a model through the UI and confirm it remains available after a service restart.
5. To roll back, restore the prior NixOS generation. If the LiteLLM schema was changed, restore the pre-upgrade PostgreSQL backup as well; generation rollback does not reverse database changes.
