# Proposal

## Why

The shared pi-box image currently provides Debian Neovim 0.7.2, while the host uses Neovim 0.12.4; the mounted Nixvim configuration also requires plugins such as TokyoNight that are unavailable in the image. Use a current Neovim release and package the configuration's plugin runtime into the image so Ctrl+G works without exposing the host Nix store.

## What Changes

- Replace Debian's Neovim with the official latest stable Linux x86_64 release (v0.12.6 at this plan update), pinned and checksum-verified in the shared `pi-sandbox` image; derived project images inherit it.
- Package the plugins and runtime assets required by the mounted host Nixvim config—including TokyoNight and its configured plugin dependencies—inside the image. Do not mount the host Nix store for plugin/runtime files.
- Keep Neovim as Pi's `EDITOR` fallback; an explicit Pi `externalEditor` setting remains higher priority.
- Mount the host's `~/.config/nvim` read-only at `/root/.config/nvim` when that directory exists.
- Keep the sandbox grant documentation, `pi-box` help text, repository instructions, and shipped template comments accurate. Keep Git's separate container-safe editor configuration unchanged.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `pi-box-sandbox`: provide a current Neovim editor with its mounted Nixvim plugin runtime, while keeping the config mount read-only and the default host grants constrained.

## Impact

- `home-manager/pi-sandbox.Dockerfile`: pinned Neovim release, image-local Nixvim plugin runtime, and editor environment.
- `home-manager/pi-box.sh`: default read-only config mount using the existing helper and accurate grant text (already implemented).
- The `pi-box-sandbox` spec delta, `AGENTS.md`, and shipped `Dockerfile.pi` comments: sandbox-grant and common-toolchain documentation (already updated).
- All project images inherit the editor runtime; no host Nix-store plugin mounts or per-project editor installations are intended.
