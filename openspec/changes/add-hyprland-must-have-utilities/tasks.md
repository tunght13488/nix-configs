## 1. Add Home Manager Hyprland utilities

- [ ] 1.1 Create `home-manager/hyprland.nix` for the Hyprland-specific user utilities and keep the existing unmanaged Hyprland configuration outside Home Manager ownership.
- [ ] 1.2 Enable the Home Manager `services.fnott` module without introducing an alternative notification daemon or custom styling.
- [ ] 1.3 Enable the Home Manager `services.hyprpolkitagent` module so the graphical PolicyKit agent is managed as a user service.
- [ ] 1.4 Add `noto-fonts`, `pkgs.qt5.qtwayland`, and `pkgs.qt6.qtwayland` to the managed user environment, preserving the existing Monaspace and Nerd Font packages.
- [ ] 1.5 Add Wayland and Hyprland session environment conditions to the generated fnott and hyprpolkitagent user services so they do not become active during GNOME sessions.

## 2. Integrate and evaluate the configuration

- [ ] 2.1 Import `home-manager/hyprland.nix` from `home-manager/home.nix` without enabling `wayland.windowManager.hyprland` or generating a Home Manager-owned Hyprland configuration file.
- [ ] 2.2 Format the changed Nix files with `nixpkgs-fmt`.
- [ ] 2.3 Run `make home-build` and resolve any Home Manager option, package, or systemd-unit evaluation errors.
- [ ] 2.4 Inspect the evaluated Home Manager generation to confirm fnott, hyprpolkitagent, Noto fonts, and both Qt Wayland packages are present, while existing NixOS-owned PipeWire, portal, XWayland, and PolicyKit integration remains unchanged.

## 3. Validate both desktop sessions

- [ ] 3.1 Activate the Home Manager generation as a user while retaining the previous generation for rollback.
- [ ] 3.2 Log into `Hyprland (uwsm-managed)` from GDM and verify that fnott displays a desktop notification without manual startup.
- [ ] 3.3 In the UWSM-managed Hyprland session, trigger a graphical PolicyKit authorization request and verify that hyprpolkitagent displays a working password prompt.
- [ ] 3.4 Repeat notification and PolicyKit checks in the regular `Hyprland` GDM session if the session is needed for comparison.
- [ ] 3.5 Verify Noto font discovery and Qt 5/Qt 6 Wayland plugin availability from the Hyprland session.
- [ ] 3.6 Return to GNOME and verify that GNOME remains the default usable session, its notification/authentication services remain in control, and fnott and hyprpolkitagent are inactive there.
