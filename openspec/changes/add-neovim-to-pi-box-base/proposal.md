# Proposal

## Why

The shared pi-box image lacks Neovim, so Pi's Ctrl+G external-editor action cannot use the host's configured editor inside the sandbox. Providing Neovim and the host configuration as a read-only mount makes that workflow available without making editor configuration writable from the sandbox.

## What Changes

- Add Neovim to the shared `pi-sandbox` image so the executable is inherited by project images.
- Configure Neovim as Pi's default external editor in the sandbox. An explicit Pi `externalEditor` setting remains higher priority than the environment fallback.
- Mount the host's `~/.config/nvim` read-only at `/root/.config/nvim` when that directory exists; do not add a store-wide Nix mount or host grants beyond this config.
- Update the sandbox's default-grant contract, `pi-box` help text, repository instructions, and shipped template comments to describe the added tool and mount. Keep Git's separate container-safe editor configuration unchanged.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `pi-box-sandbox`: add Neovim-based Pi external editing and the read-only Neovim configuration mount to the shared sandbox behavior and default grants.

## Impact

- `home-manager/pi-sandbox.Dockerfile`: shared image package and editor environment.
- `home-manager/pi-box.sh`: default read-only mount using the existing config-mount helper, plus accurate default-grant help text.
- The `pi-box-sandbox` spec delta, `AGENTS.md`, and the shipped `Dockerfile.pi` comment headers: update the sandbox grant and common-toolchain documentation.
- All project images inherit Neovim from `pi-sandbox`; no per-project Neovim installations or host Neovim changes are intended.
