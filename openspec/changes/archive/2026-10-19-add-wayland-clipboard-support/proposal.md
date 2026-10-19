# Proposal

## Why

Herdr's click-to-copy feature fails with "clipboard unavailable: install `wl-clipboard` (`wl-copy`) or check wayland access" because the managed user environment does not provide `wl-copy`. The package is absent from the Home Manager configuration, so clipboard CLI tooling is missing in both GNOME and Hyprland sessions.

## What Changes

- Add the `wl-clipboard` package to the managed user environment so `wl-copy` and `wl-paste` are available on PATH.
- Make the tools available in both the GNOME session (current default) and the optional Hyprland session, since herdr and the terminal setup are configured globally and click-to-copy should work regardless of session.
- Keep the change scoped to the clipboard CLI tools only; no clipboard manager, daemon, or keybinding configuration.

## Capabilities

### New Capabilities

- `wayland-clipboard`: Declarative availability of the Wayland clipboard CLI tools (`wl-copy`, `wl-paste`) in the managed user environment, so terminal tools such as herdr can copy to the Wayland clipboard.

### Modified Capabilities

<!-- No existing capability requirements change; this is an additive capability. -->

## Impact

- Home Manager configuration and the managed user package closure.
- Herdr click-to-copy behavior after the Home Manager generation is applied.
- No new flake inputs, system services, or changes to existing terminal or herdr configuration.
