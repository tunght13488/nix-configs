# Design

## Context

`nixos/configuration.nix` has a GNOME configuration block that enables GDM and GNOME but does not explicitly configure Tracker or Tracker Miners. The implementation must preserve the existing GNOME/GDM login path and meet the behavior in `specs/gnome-tracker/spec.md`.

## Goals / Non-Goals

**Goals:**
- Disable both Tracker services through the existing NixOS configuration.
- Keep GNOME and GDM enabled and avoid unrelated desktop changes.

**Non-Goals:**
- Remove Tracker packages or other GNOME components.
- Change GNOME search applications, Hyprland, or session defaults.
- Delete existing Tracker data or migrate user data.

## Decisions

- Set `services.gnome.tracker.enable` and `services.gnome.tracker-miners.enable` to `false` in the existing GNOME block of `nixos/configuration.nix`. These are the requested NixOS service controls and keep the change localized to the system configuration. Removing packages or disabling GNOME would have a broader effect than disabling the services.
- Leave GNOME, GDM, and the default session settings unchanged, preserving the existing desktop and Hyprland-session requirements.
- Validate the resulting system configuration with `make os-build`, the repository's prescribed NixOS build check.

## Risks / Trade-offs

- Tracker-backed content indexing and search may be unavailable or incomplete. This is the direct consequence of disabling the services; the rest of GNOME remains enabled.
- Existing Tracker data is not cleaned up. Avoiding data deletion keeps the configuration change reversible and non-destructive.

## Migration Plan

No data migration is needed. Build the configuration before activation with `make os-build`. To roll back, remove the two explicit disable settings (or enable the services again) and rebuild the system generation.
