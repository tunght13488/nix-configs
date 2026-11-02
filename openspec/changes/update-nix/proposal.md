# Proposal

## Why

Refresh the pinned revisions of the stable NixOS and Home Manager inputs to pick up current fixes and package updates while staying on the existing 26.05 release lines. The 26.11 release is not stable yet, so this change must not advance either branch.

## What Changes

- Update the lockfile revisions for `nixpkgs` (`nixos-26.05`) and `home-manager` (`release-26.05`), preserving their declared release branches and the Home Manager `nixpkgs.follows` relationship.
- Leave `nixpkgs-2511`, `nixpkgs-unstable`, Nixvim, and other unrelated inputs unchanged.
- Keep `system.stateVersion` and `home.stateVersion` unchanged; this is a flake-input refresh, not a state migration.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is dependency and lockfile maintenance with no new spec-level behavior; `.openspec.yaml` sets `skip_specs: true`.

## Impact

- `flake.lock` and the evaluated NixOS and Home Manager configurations that consume the refreshed inputs.
- Validate both configurations with `make os-build` and `make home-build`; do not activate either configuration as part of this change.
