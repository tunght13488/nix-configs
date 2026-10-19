# Proposal

## Why

Obsidian is the knowledge-management app for this machine, and upstream distributes Linux releases as an AppImage. The nixpkgs `obsidian` package (1.13.4 on nixos-26.05, 1.12.7 on the locked nixpkgs-unstable) builds from a source tarball rather than the official AppImage and lags upstream (1.14.4), so this config should wrap the official AppImage directly, following the existing precedent of pinning upstream binaries (e.g. the postman override).

## What Changes

- Add a custom package `pkgs/obsidian.nix` that wraps the official Obsidian AppImage from GitHub releases via `appimageTools.wrapType2` (from the nixos-26.05 input), pinned to an upstream version with a fixed-output hash.
- Ship a desktop entry and icon with the package so Obsidian appears in the GNOME application grid.
- Expose the package through the `additions` overlay (`pkgs.obsidian`) and the flake packages output (`nix build .#obsidian`).
- Install `obsidian` for user `tung` via `home.packages` in `home-manager/home.nix`.
- No flake input or `flake.lock` changes.

## Capabilities

### New Capabilities

- `obsidian-app`: Sourcing, version pinning, desktop integration, and update mechanics of the Obsidian desktop app within the NixOS + home-manager configuration.

### Modified Capabilities

None.

## Impact

- New file `pkgs/obsidian.nix`; modified `pkgs/default.nix` and `home-manager/home.nix`.
- No system services; the `programs.appimage` NixOS module (raw-AppImage binfmt) is untouched and unrelated to the wrapped package.
- User data (`~/.config/obsidian`, vault directories) is out of scope and unaffected.
