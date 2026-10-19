# Tasks

## 1. Add wl-clipboard to the managed user environment

- [x] 1.1 Add `wl-clipboard` to the `home.packages` list in `home-manager/terminal.nix` and run `nixpkgs-fmt` on the file
- [x] 1.2 Run `make home-build` and verify the Home Manager configuration evaluates without errors
- [x] 1.3 Inspect the evaluated generation to confirm `wl-copy` and `wl-paste` are present in the user package closure and no new services or keybindings were introduced

## 2. Verify clipboard behavior in both sessions

- [x] 2.1 Activate the Home Manager generation while retaining the previous generation for rollback
- [x] 2.2 In a GNOME session, run `wl-copy test && wl-paste` and verify the round-trip returns the copied text
- [x] 2.3 In a GNOME session, use herdr's click-to-copy and verify the copied text lands in the Wayland clipboard without the "clipboard unavailable" error
- [ ] 2.4 In a regular or UWSM-managed Hyprland session, repeat the `wl-copy`/`wl-paste` round-trip and herdr click-to-copy checks from 2.2 and 2.3

## Workflow follow-up

- Archive the change after the verification tasks are complete.
- Verify the archived result.
