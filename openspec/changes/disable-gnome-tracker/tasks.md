# Tasks

## 1. Disable GNOME Tracker services

- [x] 1.1 Set `services.gnome.tracker.enable` and `services.gnome.tracker-miners.enable` to `false` in the GNOME block of `nixos/configuration.nix`, preserving GNOME and GDM settings; verify both options are false in the diff and `make os-build` succeeds.
