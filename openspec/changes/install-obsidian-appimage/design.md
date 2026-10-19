# Design

## Context

Single-machine NixOS + home-manager configuration (`nixos-vmware`, user `tung`), flake pinned to `nixos-26.05`. Custom packages live in `pkgs/` and are exposed via the `additions` overlay and the flake `packages` output (see `pkgs/maven363.nix`); GUI apps are installed through `home.packages` (postman, jetbrains-toolbox, zed-editor). See proposal.md for motivation.

Verified against the pinned inputs:
- `appimageTools.wrapType2` exists in `nixos-26.05` and wraps an extracted AppImage in a `buildFHSEnv` (gtk3, glib, libsecret, xdg-utils, etc.). It does **not** install desktop entries itself.
- Upstream latest: v1.14.4 (`Obsidian-1.14.4.AppImage`). nixpkgs `obsidian`: 1.13.4 on 26.05, 1.12.7 on the locked unstable — both built from a source tarball, not the AppImage.
- `programs.appimage.enable`/`binfmt` are already set in `nixos/configuration.nix`; they serve raw AppImages and are unrelated to a wrapped package.
- nixpkgs precedent for AppImage + desktop entry: `losslesscut-bin` (extract + `wrapType2` + `extraInstallCommands` linking the embedded `share/` tree), and `cura-appimage` (own desktop file via `copyDesktopItems`).

## Goals / Non-Goals

**Goals:**
- A reproducible, pinned `obsidian` package built from the official AppImage, with a working desktop entry and icon.
- An update path that is a simple version + hash repin with no `flake.lock` churn.

**Non-Goals:**
- Automatic updates (`nix-update` script) — can be added later if wanted.
- `aarch64-linux` builds — the host is `x86_64-linux` and only the x86_64 AppImage is targeted.
- Obsidian sync, plugins, themes, or vault management.

## Decisions

### D1: Custom `pkgs/obsidian.nix` wrapping the official AppImage, not nixpkgs `obsidian`

Wrap the official AppImage with `appimageTools.wrapType2` from the `nixos-26.05` input.

- Rationale: this is the only route that matches the AppImage intent; the nixpkgs package builds from a tarball and lags upstream.
- Alternatives considered:
  - `pkgs.unstable.obsidian` — tarball-built and older (1.12.7) than 26.05's own package; rejected.
  - Raw AppImage in `~/.local` + binfmt — no desktop entry management, updates are manual and untracked; rejected.

### D2: Pin version 1.14.4 with `fetchurl` and a hash computed at implementation time

`pkgs/obsidian.nix` declares `version = "1.14.4"` and a fixed-output hash fetched from `https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/Obsidian-${version}.AppImage`.

- Rationale: matches the postman-app pinning precedent; keeps `flake.lock` byte-identical (spec requirement).
- The hash MUST be obtained with `nix-prefetch-url` (or equivalent) during implementation — never guessed.
- Updates are a version + hash bump in one file; no other changes.

### D3: Desktop entry via the `losslesscut-bin` pattern

Extract the AppImage once with `appimageTools.extractType2`, then in `wrapType2`'s `extraInstallCommands` symlink the extracted `usr/share` tree (icons, applications) into `$out/share` and rewrite the desktop file's `Exec` to point at the wrapped `obsidian` binary.

- Rationale: reuses upstream's own desktop metadata and icon instead of maintaining a hand-written copy.
- Fallback if the embedded desktop file turns out malformed or missing paths: generate one with `makeDesktopItem` (the `cura-appimage` pattern). The extracted tree is inspected during implementation before committing to D3.

### D4: Exposure and installation follow existing conventions

- `pkgs/default.nix` gains `obsidian = pkgs.callPackage ./obsidian.nix { };` — this makes it available as both `pkgs.obsidian` (additions overlay) and `nix build .#obsidian` (flake packages output).
- `home-manager/home.nix` adds `obsidian` to `home.packages` alongside the other GUI apps.
- Package metadata: `pname = "obsidian"` (gives the `obsidian` binary), `meta.platforms = [ "x86_64-linux" ]`, `meta.mainProgram = "obsidian"`.

## Risks / Trade-offs

- [AppImage internal layout drifts upstream (desktop file / icon paths change)] → Version + hash are pinned, so behavior changes only on an explicit repin; inspect the extracted tree each repin. Fallback: `makeDesktopItem`.
- [Electron app missing runtime deps under the FHS env] → `wrapType2`'s default target packages cover gtk3/xdg-utils; launch-test on the host and add `extraPkgs` only if something fails.
- [Wayland/GNOME quirks (rendering, portal dialogs)] → Test on the host; add wrapper flags only if an issue is actually observed.
- [Manual repinning on upstream releases] → Accepted; update procedure is a documented two-line change. An update script can be added later.
- [Hardcoded hash errors] → `nix build .#obsidian` fails loudly on mismatch; hash is computed, not fabricated.

## Migration Plan

1. Add package and wire overlay + home-manager; verify with `nix build .#obsidian` and `make home-build`.
2. User runs `make home` to activate.
3. Rollback: remove `obsidian` from `home.packages` and revert the package files (`git revert`). No state outside `~/.config/obsidian` and user vaults, which persist untouched by design.

## Open Questions

None.
