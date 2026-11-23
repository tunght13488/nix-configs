# Proposal

## Why

The pi-box base profile diverges from the registry's Pi profile by filtering outbound traffic through a developer-domain allowlist, which blocks destinations such as `pi.dev`; it also cannot run the host-installed OpenSpec CLI. Inheriting `nolabs-ai/pi` gives pi-box the upstream Pi baseline, while moving the brokered GitHub token outside `~/.pi` preserves its secrecy despite the upstream profile's broader `~/.pi` grant.

## What Changes

- Make the shared pi-box profile extend `nolabs-ai/pi` and inherit its default-allow network policy and full upstream grants, including read-write access to `~/.pi` and `~/.cache` via `user_caches_linux`. Remove pi-box's local network profile and domain allowlist so outbound access is not filtered to a fixed host list.
- Keep pi-box's host-specific grants, environment restrictions, per-run workspace grants, and brokered GitHub credential route. Keep endpoint rules on the credential route; they restrict use of the injected GitHub token, not general outbound traffic.
- Move the GitHub token from `~/.pi/sandbox/gh-token` to `~/.config/nono/credentials/pi-box-gh-token`, update setup documentation and the wrapper, and prevent a run while the legacy token remains under `~/.pi`.
- Grant read-only access to the host-installed OpenSpec package and make `~/.npm-global/bin` available in the sandbox launcher PATH so `openspec` works by name.
- Update the pi-box sandbox specification and project instructions for upstream inheritance, default outbound access, the token migration, and OpenSpec availability.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `pi-box-sandbox`: Change the base profile and default network behavior; preserve the brokered token boundary with a token path outside the inherited `~/.pi` grant; make the host OpenSpec CLI available in the sandbox.

## Impact

- Affected files: `home-manager/pi-sandbox.nix`, `home-manager/pi-box.sh`, `AGENTS.md`, and `openspec/specs/pi-box-sandbox/spec.md`.
- Runtime dependency: the `nolabs-ai/pi` registry profile must be installed for Nono to resolve the base profile. It is already present on this host; this change does not add automatic package installation.
- The existing `pi-box-templates` requirement for OpenSpec availability remains satisfied through the shared base profile; no template behavior change is needed.
- The existing token must be moved before activating the new base profile, because the upstream Pi profile grants read-write access to `~/.pi`.
- Full inheritance intentionally supersedes pi-box's prior `~/.cache` exclusion: the registry's `user_caches_linux` group grants it read-write access.
