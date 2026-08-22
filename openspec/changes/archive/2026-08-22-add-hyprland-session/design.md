## Context

See proposal.md for the motivation and scope. The host is pinned to NixOS 26.05 and currently enables `services.xserver`, GDM, and GNOME in `nixos/configuration.nix`; `nixos/vmware.nix` supplies the VMware video driver and guest tools. There is no Hyprland or Home Manager Hyprland configuration today. The existing live session is GNOME running on Wayland, but the VMware `vmwgfx` path still needs to be tested with Hyprland.

## Goals / Non-Goals

**Goals:**

- Make Hyprland selectable from the existing GDM session chooser.
- Provide both the normal Hyprland session and the UWSM-managed session supported by the pinned package.
- Keep GNOME as the explicit default and preserve it as a working fallback.
- Keep the change limited enough that VMware graphics and session startup can be tested independently of a new desktop-shell configuration.

**Non-Goals:**

- Replacing GDM, disabling GNOME, or disabling the existing X server/VMware configuration.
- Adding a bar, launcher, notification daemon, lock screen, wallpaper system, or application-specific keybindings.
- Adding a Home Manager Hyprland configuration, choosing between Hyprland's Lua and hyprlang configuration formats, or changing either state version.
- Adding a separate Hyprland flake input or tracking an unstable Hyprland build.

## Decisions

### Use the NixOS Hyprland module from the pinned package set

Enable `programs.hyprland` from the existing NixOS configuration rather than adding a separate flake input or installing Hyprland only through Home Manager. The NixOS module registers the compositor's session entries with `services.displayManager.sessionPackages` and provides the associated XWayland, portal, and polkit integration. This keeps the package aligned with the host's pinned NixOS release and avoids duplicating system-level session wiring.

### Retain GDM and GNOME during the test

Leave the existing GDM and GNOME declarations in place. GDM is compatible with the Hyprland session entries, so it provides a graphical session chooser and an immediate GNOME fallback if the VMware compositor session fails. Replacing the display manager is deliberately deferred because it would combine login-manager migration with graphics debugging.

### Make GNOME the explicit default session

Set `services.displayManager.defaultSession` to `gnome`. The current configuration relies on the implicit ordering of its only desktop session; adding Hyprland would make that implicit behavior fragile. An explicit GNOME default ensures that ordinary logins remain unchanged while the user can select Hyprland for testing.

### Enable UWSM through the Hyprland module

Set the Hyprland module's `withUWSM` option. This enables the systemd-integrated Hyprland session recommended for current NixOS and exposes the `hyprland-uwsm` session alongside the regular `hyprland` entry. The user can test the UWSM entry first and compare with the regular entry if needed. No separate `programs.uwsm` declaration is necessary because the Hyprland module enables it.

### Defer declarative Hyprland desktop configuration

Do not enable `wayland.windowManager.hyprland` in Home Manager for this initial test. The immediate acceptance question is whether the compositor session can start correctly on the VMware graphics stack, not whether a complete Hyprland desktop is configured. Deferring Home Manager configuration also avoids prematurely choosing a configuration format while this repository's Home Manager state version is still `25.11`.

### Preserve the VMware and X server declarations

Do not alter `nixos/vmware.nix`, `services.xserver.enable`, or the existing GNOME-specific settings. Although Hyprland is Wayland-native, these declarations support the known-good GDM/GNOME path and may still affect XWayland or VMware-related integration. Any cleanup after a successful test should be a separate, explicitly scoped change.

## Risks / Trade-offs

- [Hyprland or Aquamarine behaves poorly with VMware `vmwgfx`, including a blank display, incorrect resolution, rendering failures, or input problems] → Keep GDM/GNOME unchanged, test from the additional session, and return to GNOME from the same chooser without changing generations.
- [UWSM introduces a session-startup or systemd-environment problem] → Keep the regular `hyprland` session registered as a comparison path; the GNOME session remains the default fallback.
- [The bare Hyprland session is not immediately comfortable because no bar, launcher, or custom keybindings are configured] → Treat this change as a compositor/startup compatibility test only; add desktop components in a follow-up after the graphics path is proven.
- [Adding Hyprland changes effective XWayland or portal defaults] → Validate the evaluated system and test both native Wayland and existing X11 applications while leaving the prior GNOME configuration intact.

## Migration Plan

1. Add the system-level Hyprland and UWSM options and explicitly retain GNOME as the default session.
2. Format the Nix configuration and run `make os-build`; confirm that the generation evaluates and that the Hyprland session entries are registered.
3. Activate the resulting system generation outside the planning/apply step, keeping the existing generation available for rollback.
4. At GDM, select `Hyprland (UWSM)` for the first test. If it fails to start or behaves incorrectly, return to the chooser and select GNOME; optionally compare with the regular Hyprland entry.
5. Record VMware graphics, display, input, terminal/application, portal, and logout results before deciding whether a full Hyprland desktop configuration or display-manager replacement is warranted.

## Open Questions

None for this test-only scope. Decisions about the Hyprland desktop shell, configuration format, and eventual GDM replacement should be made after the compositor compatibility test.
