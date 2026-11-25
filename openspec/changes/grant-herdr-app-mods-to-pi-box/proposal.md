# Proposal

## Why

The shared pi-box base profile does not currently grant access to `~/.config/herdr-app/mods`, so sandboxed Pi sessions cannot use the host's Herdr mods directory. Granting only this directory read-write makes the mods available without exposing the rest of Herdr's configuration.

## What Changes

- Add `~/.config/herdr-app/mods` as a read-write grant in the shared pi-box base profile for all pi-box sessions.
- Update the pi-box sandbox contract to require access to this directory while keeping the grant scoped to `mods`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `pi-box-sandbox`: Include the Herdr mods directory in the default read-write grants.

## Impact

- `home-manager/pi-sandbox.nix`: shared base profile filesystem grants.
- `openspec/specs/pi-box-sandbox/spec.md`: default grant behavior.
- No per-project template or wrapper changes; the shared base profile applies to every pi-box session.
