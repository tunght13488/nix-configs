# Proposal

## Why

Herdr split off `herdr-core` (`hc`), a headless core that keeps terminals and coding agents alive and exposes a CLI/socket API for agents. This repo installs only the herdr TUI; adding `hc` alongside it gives agents and scripts a durable terminal runtime from the shell. Separately, the herdr input is pinned to a fixed tag and should follow the latest stable release.

## What Changes

- Add a Nix package derivation `pkgs/herdr-core.nix` that builds the `hc` binary from `github:herdrdev/herdr-core` pinned at tag `v0.1.21` (fetched with its Ghostty vendor submodule), exposed through the `additions` overlay and as `nix build .#herdr-core`.
- Install `herdr-core` into the managed user environment via `home.packages` in `home-manager/home.nix`, alongside the herdr TUI.
- Confirm the herdr input tracks the latest stable release with `nix flake update herdr`; if a stable release newer than the current pin (v0.9.5, the latest at implementation time) exists, bump the pin to it.
- Keep the herdr TUI installed and its config bootstrapping and skill linking unchanged; `hc` is additive, not a replacement.

## Capabilities

### New Capabilities

- `herdr-core`: The `hc` binary is available on PATH via home-manager, built from the pinned `herdrdev/herdr-core` source through the additions overlay.

### Modified Capabilities

- `herdr-terminal-multiplexer`: The herdr flake input pin changes from a fixed v0.9.5 tag to tracking the latest stable release.

## Impact

- `flake.nix` and `flake.lock` (refreshed `herdr` lock entry only; no new input).
- New file `pkgs/herdr-core.nix`, `pkgs/default.nix` and `overlays/default.nix` (addition exposure).
- `home-manager/home.nix` (package added to the managed user environment).
- Build-time requirements: recent Rust toolchain (edition 2024), Zig 0.16 for the vendored Ghostty submodule, and network-free Zig dependency vendoring.
- No NixOS-level changes, no changes to the pi-box sandbox or the herdr agent skill linking.
