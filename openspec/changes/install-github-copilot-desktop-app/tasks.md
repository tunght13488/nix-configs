# Tasks

## 1. Package the official desktop app

- [ ] 1.1 Add a pinned x86_64 Linux AppImage package in `pkgs/github-copilot-app.nix`, expose it through `pkgs/default.nix`, and wire its desktop entry and icon to the wrapped executable; stage the new Nix file before evaluation, then verify with `nix build .#github-copilot-app` and inspect the built launcher and icon.

## 2. Install and validate through Home Manager

- [ ] 2.1 Add the app to `home-manager/ai.nix` without removing `github-copilot-cli`; run `make format` and `make home-build`, and confirm the existing CLI and Neovim Copilot configuration remain unchanged.
- [ ] 2.2 After a human activates the Home Manager generation, launch the app from GNOME's application grid and verify its window opens and the existing Copilot CLI remains usable.
