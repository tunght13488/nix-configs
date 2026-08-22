## Why

The VMware NixOS host currently provides GNOME through GDM, but there is no Hyprland session available for evaluating a tiling Wayland compositor. Hyprland should be introduced as an optional session so its graphics and desktop integration can be tested without disrupting the known-good GNOME login path.

## What Changes

- Enable the NixOS Hyprland module and its UWSM-managed session.
- Register Hyprland as an additional session in the existing GDM login screen.
- Keep GDM, GNOME, the existing X server/VMware configuration, and GNOME's default-session behavior intact.
- Do not remove or replace GNOME or GDM, and do not introduce a custom Hyprland desktop configuration in this initial test scope.
- Preserve a straightforward rollback path through the existing GNOME session if Hyprland has VMware-specific graphics or integration problems.

## Capabilities

### New Capabilities

- `hyprland-session`: An optional Hyprland Wayland session selectable from the existing GDM login manager while GNOME remains the default and available fallback.

### Modified Capabilities

None.

## Impact

- `nixos/configuration.nix` will gain the system-level Hyprland/UWSM session configuration.
- The pinned NixOS 26.05 package set will provide Hyprland, its session entries, XWayland support, desktop portals, and polkit integration through the NixOS module.
- GDM's available-session list will include the regular Hyprland and UWSM-managed Hyprland sessions.
- The VMware guest configuration and video driver remain unchanged; actual compositor performance, display handling, input, and application compatibility will be validated by the user after activation.
- No new flake input, application API, service migration, or GNOME package removal is required.
