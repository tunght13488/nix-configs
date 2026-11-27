# Design

## Context

The PHP82 and PHP83 templates currently declare `network.connect_port: [3306]` and set `DB_HOST=127.0.0.1`. The shared pi-box base inherits the registry profile's default-allow network policy. On Linux, Nono treats `connect_port` as a TCP port allowlist, so the PHP profile narrows direct outbound connections to port 3306 and model requests to port 443 fail. The user's affected run had no `HTTPS_PROXY`; removing the port restriction restored model access.

`pi-box init` copies a template into an ignored, project-local `pi-box.profile.json`. The wrapper leaves an existing file alone unless the user explicitly overwrites it, so template updates do not migrate existing project profiles.

## Goals / Non-Goals

**Goals:**
- Keep default outbound HTTPS available when PHP82/PHP83 profiles extend the standard pi-box base.
- Retain the `DB_HOST=127.0.0.1` configuration and host MySQL access under that base.
- Add a small regression check for both PHP templates.

**Non-Goals:**
- Change the shared base profile, per-run overlay, or Nono proxy behavior.
- Rewrite profiles already scaffolded into user projects.
- Introduce a restricted-egress policy for PHP projects.

## Decisions

- Remove `network.connect_port` from both PHP templates rather than adding port 443 or substituting another port grant. The standard base already allows outbound TCP, including MySQL and HTTPS; a port-specific allowlist is unnecessary there and narrows that policy.
- Keep `DB_HOST` unchanged. Under the default base, host MySQL remains reachable without an additional port rule.
- Extend the existing `home-manager/pi-box-check.sh` regression check to parse the PHP template JSON and assert that neither template declares `network.connect_port` and both retain `DB_HOST=127.0.0.1`. This covers the configuration contract without making tests depend on live model endpoints.

## Risks / Trade-offs

- A user who deliberately replaces the default network policy with a blocked or proxy-only policy may need a separate database-access design. This change targets the default-allow configuration specified by the PHP template requirements.
- Existing project-local profiles retain the old field until users update them; the scaffold command intentionally does not overwrite existing files.

## Migration Plan

Deploy the updated templates with Home Manager. New PHP82/PHP83 scaffolds will omit the port restriction. Existing projects must remove `network.connect_port` from their own `pi-box.profile.json`; no automatic rewrite or backup is performed by this change.

## Open Questions

None.
