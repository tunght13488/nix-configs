## Why

The optional Hyprland session now starts through GDM, but it does not yet provide the user-level notification and authentication services that Hyprland expects from a desktop environment. The Hyprland wiki also recommends explicit font coverage and Qt Wayland support; adding these declaratively now will make the session usable while preserving GNOME as the default fallback.

## What Changes

- Add `fnott` as the single notification daemon for the Hyprland session.
- Add `hyprpolkitagent` as the Hyprland session's graphical PolicyKit authentication agent.
- Add the recommended Noto fonts and explicit Qt 5 and Qt 6 Wayland support to the managed user environment.
- Start the notification and authentication services only for the Hyprland session, without competing with GNOME's existing desktop services.
- Keep the existing PipeWire, WirePlumber, XDG desktop portal, XWayland, Kitty, and Nerd Font setup; do not duplicate components already supplied by the NixOS Hyprland or GNOME modules.
- Do not add alternative notification daemons, a status bar, launcher, wallpaper manager, lock screen, or broader Hyprland desktop configuration.

## Capabilities

### New Capabilities

- `hyprland-must-have-utilities`: Declarative notification, PolicyKit authentication, font, and Qt Wayland support for the optional Hyprland session.

### Modified Capabilities

<!-- The existing hyprland-session requirements remain unchanged; this is an additive capability. -->

## Impact

- Home Manager configuration and the managed user package closure.
- Hyprland session startup and user-level systemd service wiring.
- Notification and PolicyKit behavior when the user selects Hyprland from GDM.
- The existing GNOME default session must remain unchanged and usable as a fallback.
- No new flake inputs, system services, or changes to the VMware graphics configuration are required.
