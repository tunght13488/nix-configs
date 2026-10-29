# Proposal

## Why

Run LiteLLM directly as a NixOS-managed service instead of using Docker Compose, while retaining the existing local HTTPS endpoint. PostgreSQL will provide persistent proxy state and enable adding models and provider credentials through the Admin UI after deployment, without deciding the model list up front.

## What Changes

- Configure the native NixOS LiteLLM service behind the existing `litellm.vm.local` nginx vhost, including support for long-lived streaming responses.
- Add a local PostgreSQL database for LiteLLM, listening only on loopback and using the requested loopback trust authentication.
- Enable database-backed model management so models and provider credentials can be added and maintained in the Admin UI; no initial static model list is required.
- Keep the admin master key and credential-encryption salt out of the Nix store using the existing agenix workflow.
- Ensure LiteLLM's Prisma schema setup works with the packaged NixOS service and PostgreSQL, without relying on Docker.

## Capabilities

### New Capabilities
- `litellm-gateway`: Provide a locally hosted LiteLLM API and Admin UI with persistent PostgreSQL-backed model management, exposed through the existing HTTPS reverse proxy.

### Modified Capabilities

None.

## Impact

- NixOS configuration and service modules: `nixos/configuration.nix`, a LiteLLM module, and a PostgreSQL module.
- Existing nginx vhost: `nixos/vhosts/litellm.vm.local.nix`.
- Flake module wiring for NixOS agenix, plus `secrets/secrets.nix` and a new encrypted LiteLLM secret.
- NixOS evaluation/build and service startup verification, including Prisma schema initialization and UI/API access through the vhost.
