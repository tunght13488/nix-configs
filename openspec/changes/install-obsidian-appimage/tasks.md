# Tasks

## 1. Package definition

- [ ] 1.1 Compute the hash for the pinned AppImage with `nix-prefetch-url https://github.com/obsidianmd/obsidian-releases/releases/download/v1.14.4/Obsidian-1.14.4.AppImage` and verify it prints a sha256
- [ ] 1.2 Extract the AppImage in a scratch derivation under `.tmp/` and verify the embedded `usr/share/applications/obsidian.desktop` and icon files exist; if they are missing, plan the `makeDesktopItem` fallback from design D3
- [ ] 1.3 Write `pkgs/obsidian.nix` per design D1-D3 (wrapType2 with pinned version/hash and `extraInstallCommands` installing the desktop entry and icons) and verify `nixpkgs-fmt` leaves it unchanged
- [ ] 1.4 Register `obsidian` in `pkgs/default.nix`, `git add` the new files, and verify `nix build .#obsidian` succeeds and the result contains `bin/obsidian`, `share/applications/obsidian.desktop`, and an icon under `share/icons`

## 2. Installation

- [ ] 2.1 Add `obsidian` to `home.packages` in `home-manager/home.nix` and verify `make home-build` succeeds
- [ ] 2.2 Launch the built package (`nix run .#obsidian`) and verify the Obsidian window opens, then quit the app
- [ ] 2.3 Ask the user to run `make home` and verify Obsidian appears in the GNOME application grid and launches from it

## 3. Validation

- [ ] 3.1 Run `openspec validate install-obsidian-appimage --strict` and verify it passes without warnings
- [ ] 3.2 Verify `git diff --name-only` shows changes only under `pkgs/`, `home-manager/`, and the change's `openspec/changes/install-obsidian-appimage/` artifacts, confirming `flake.lock` is untouched

## Workflow follow-up

- Archive the change after the project's review requirements are satisfied.
- Verify the archived result.
