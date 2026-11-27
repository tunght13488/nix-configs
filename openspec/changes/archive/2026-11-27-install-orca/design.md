# Design

## Context

See `proposal.md` for motivation. Current state and constraints that shape the approach:

- Orca is not in nixpkgs (26.05's `orca` is the GNOME screen reader, unrelated).
- Upstream ships Linux only as an AppImage (`orca-linux.AppImage`, ~287 MB, MIT-licensed) or distro packages; latest release at planning time is `v1.4.279`.
- The repo already wraps third-party desktop AppImages the same way for Obsidian and GitHub Copilot (`pkgs/obsidian.nix`, `pkgs/github-copilot-app.nix`), exposes them via the `additions` overlay (`pkgs/default.nix`), and installs them from Home Manager. Orca is agent tooling, so it belongs with the AI packages in `home-manager/ai.nix`.

## Goals / Non-Goals

**Goals:**

- A pinned, hash-verified Nix package for the official Orca AppImage, wired into the existing overlay and Home Manager flow.
- Desktop-grid launch and the bundled `orca-ide` CLI on PATH, matching how the app behaves when installed normally on Linux.

**Non-Goals:**

- Building Orca from source (Tauri/Electron monorepo, 3.6 GB repo; upstream does not publish a source build path for Linux packaging).
- Packaging the remote `orca-server` tarball or the mobile apps.
- Modifying anything about the GNOME screen-reader `orca` package.

## Decisions

1. **AppImage wrapper via `appimageTools.wrapType2`, copied from `obsidian.nix` / `github-copilot-app.nix`.** Alternative: build from source (rejected: heavy, unmaintained packaging path upstream); `.deb` unpacking via `dpkg` (rejected: more moving parts than the existing AppImage pattern; the repo precedent is AppImage). `wrapType2` extracts the AppImage, so no FUSE is needed at runtime.
2. **Package/attribute name `orca-app`, not `orca`.** nixpkgs already occupies `orca` with the GNOME screen reader; a `pkgs.orca` shadow would silently change that package for every other consumer in the overlay.
3. **Desktop entry and CLI binary wiring inside `extraInstallCommands`, adapted from `github-copilot-app.nix`.** The copilot wrapper shows the two required steps: copy upstream desktop entries and retarget their `Exec=` to the wrapper's `$out/bin/<pname>` binary, and expose inner binaries the entry needs. Orca's inner binary and desktop-entry names are not known until the AppImage is extracted (upstream CLI is `orca-ide` on Linux), so the apply tasks extract once and then finalize the `Exec` rewrite and any extra `bin/` symlinks.
4. **Pinned version + SRI hash, with update instructions in the file header.** Matches the other AppImage wrappers; upstream releases daily, so the pin is the stable contract and updates are a manual version/hash bump.
5. **Install via `home-manager/ai.nix`** alongside `github-copilot-app`, not `home.nix`: Orca is AI-agent tooling and `ai.nix` is where the other agent-app packages live. No NixOS system changes; the app is per-user.
6. **MIT license, no `allowUnfree` handling.** Unlike `github-copilot-app`, the flake-level `nix build .#orca-app` needs no `NIXPKGS_ALLOW_UNFREE` escape hatch.

## Risks / Trade-offs

- [Inner binary/desktop-entry names differ from assumption] → Extract the AppImage once during implementation before finalizing `extraInstallCommands`; the extraction step is already in the tasks.
- [App needs system libraries beyond the AppImage bundle] → The copilot wrapper needed a curl/libcurl FHS override; Orca may need similar (`fhsPkgs` tweaks). Mitigation: launch test from GNOME after build; add overrides only if the launch fails.
- [Daily upstream releases make the pin drift quickly] → Accepted: declarative pinning is the point; header documents the one-command prefetch + hash bump.
- [Large artifact (~287 MB) adds build/download time] → Same as existing AppImage wrappers; cached by the Nix store after first fetch.

## Migration Plan

1. Add `pkgs/orca.nix` + overlay entry, then `home-manager/ai.nix` line.
2. `make home-build`; launch Orca from GNOME; run `orca-ide` in a shell.
3. Rollback: revert the Home Manager change (previous generation stays intact).
