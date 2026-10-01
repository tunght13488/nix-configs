# Spec Delta

## ADDED Requirements

### Requirement: ngrok package tracks nixos-unstable
The `programs.ngrok` configuration SHALL source its package from the
`pkgs.unstable` overlay (nixos-unstable) instead of the stable nixpkgs
release, so the installed ngrok agent stays current with upstream releases.

#### Scenario: Package comes from nixos-unstable
- **WHEN** the home-manager configuration is evaluated
- **THEN** the installed `ngrok` binary is `pkgs.unstable.ngrok`, not the
  stable `pkgs.ngrok` from the pinned nixos release

#### Scenario: Flake update advances the agent
- **WHEN** `nixpkgs-unstable` is updated to a newer ngrok release and the
  configuration is rebuilt
- **THEN** the new agent version is picked up without any change to the
  module or consumer configuration

#### Scenario: Build-time config validation covers the new version
- **WHEN** the configuration is evaluated with the unstable package
- **THEN** the module's `ngrok config check` (run in `staticConfig`) runs
  against the unstable binary, so schema incompatibilities introduced by
  the newer version fail the build
