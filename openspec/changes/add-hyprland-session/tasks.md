## 1. Add Hyprland as an Additional System Session

- [ ] 1.1 Enable the NixOS Hyprland module with UWSM integration in `nixos/configuration.nix`.
- [ ] 1.2 Set `services.displayManager.defaultSession` to `gnome` while retaining the existing GDM, GNOME, X server, and VMware declarations.
- [ ] 1.3 Confirm the change does not add a Home Manager Hyprland configuration, remove GNOME/GDM, alter `nixos/vmware.nix`, or add a separate Hyprland flake input.

## 2. Evaluate and Build the Configuration

- [ ] 2.1 Format the modified Nix configuration with `nixpkgs-fmt`.
- [ ] 2.2 Run `make os-build` and resolve any evaluation or build errors.
- [ ] 2.3 Verify the evaluated display-manager session data contains `gnome`, `hyprland`, and `hyprland-uwsm`, with `gnome` as the default.

## 3. User Session Validation

- [ ] 3.1 Activate the built system generation as a user step while keeping the previous generation available for rollback.
- [ ] 3.2 Log in through GDM using `Hyprland (UWSM)` and record whether the VMware display, input, rendering, and session startup work.
- [ ] 3.3 Test the regular `Hyprland` session if the UWSM session fails or behaves differently.
- [ ] 3.4 Return to GNOME from GDM and confirm the existing GNOME session remains usable after the Hyprland tests.
- [ ] 3.5 Record application, XWayland, desktop-portal, terminal, logout, and display-resolution results to determine whether a follow-up Hyprland desktop configuration is warranted.
