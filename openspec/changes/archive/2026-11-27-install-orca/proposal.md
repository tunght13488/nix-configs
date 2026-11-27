# Proposal

## Why

The Orca desktop IDE (https://github.com/stablyai/orca) lets one machine run a fleet of coding agents side by side, each in its own worktree and terminal. It is not packaged in nixpkgs (26.05's `orca` is the GNOME screen reader), so the machine currently has no declarative way to install it.

## What Changes

- Add a pinned Nix package for the official Orca Linux AppImage, following the existing `obsidian` / `github-copilot-app` wrapper pattern in `pkgs/`.
- Expose the package via the `additions` overlay as `pkgs.orca-app` (named `orca-app` to avoid clashing with nixpkgs' GNOME screen-reader `orca`).
- Install it in the user's Home Manager package set alongside the other AI tooling in `home-manager/ai.nix`.

## Capabilities

### New Capabilities

- `orca-app`: The Orca desktop IDE packaged from the official upstream AppImage, pinned to a fixed version and hash, installed for the user, and launchable from the GNOME application grid with its bundled `orca-ide` CLI available.

### Modified Capabilities

<!-- No existing capability changes behavior. -->

## Impact

- New file `pkgs/orca.nix` and one entry in `pkgs/default.nix` (overlay exposure).
- One line in `home-manager/ai.nix` (`home.packages`).
- No new flake inputs, no NixOS system configuration changes, no other packages affected.
- The AppImage is MIT-licensed: free, so no `allowUnfree` concerns (unlike `github-copilot-app`).
- x86_64 only, matching the host and the existing AppImage wrappers.
