# Proposal

## Why

Make the system's GNOME configuration explicitly opt out of Tracker and Tracker Miners, avoiding GNOME's background indexing services while retaining the GNOME desktop. The current NixOS configuration has no explicit setting for either service.

## What Changes

- Disable `services.gnome.tracker` and `services.gnome.tracker-miners` in the NixOS configuration.
- Keep GNOME, GDM, and the rest of the desktop configuration enabled.

## Capabilities

### New Capabilities
- `gnome-tracker`: Specify that GNOME Tracker and Tracker Miners are disabled in the system configuration.

### Modified Capabilities
None. The existing `hyprland-session` requirements remain unchanged; this change does not alter desktop or session availability.

## Impact

- `nixos/configuration.nix`: GNOME service options and the evaluated NixOS system generation.
- No new dependencies or API changes. Verify the system configuration with `make os-build`.
