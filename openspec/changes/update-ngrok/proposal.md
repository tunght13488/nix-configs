# Proposal

## Why

The ngrok agent is pinned to nixos-26.05 stable, which ships 3.31.0 — well
behind upstream (3.39.5 at the repo's `nixpkgs-unstable` pin, 3.39.10 at the
current nixos-unstable tip). Staying on an old tunnel agent means missing
upstream fixes, protocol improvements, and dashboard-feature compatibility. The repo already has an established `pkgs.unstable` overlay
for exactly this situation, and other long-lived tools (opencode, git-town,
1password) already track unstable.

## What Changes

- `programs.ngrok.package` is set to `pkgs.unstable.ngrok` in
  `home-manager/ngrok.nix`, moving the agent from 3.31.0 to 3.39.5 — the
  version at the repo's current `nixpkgs-unstable` pin.
- No changes to endpoints, settings, authtoken handling, or the module
  itself — only the package source.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `ngrok-tunnel-config`: add a requirement that the ngrok package tracks
  nixos-unstable via the `pkgs.unstable` overlay, so the agent stays current
  instead of following the stable release branch.

## Impact

- **Code**: `home-manager/ngrok.nix` (one-line package override).
- **Dependencies**: pulls `ngrok` from `nixpkgs-unstable` instead of
  `nixos-26.05`; unfree license already permitted by the unstable overlay
  (`config.allowUnfree = true`).
- **Verification**: the module's build-time `ngrok config check` (in
  `staticConfig`) will run against the newer binary, so config-schema
  incompatibilities surface at build time. Verified via `make home-build`.
- **Rollback**: reverting the one-line override returns to the stable
  package; no state or config migration involved.
