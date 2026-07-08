## Why

Herdr is a modern terminal multiplexer purpose-built for AI coding agent workflows — mouse-first, session-aware, and agent-native. It integrates directly with coding agents (Claude Code, Codex, pi, etc.) and offers session persistence, detach/reattach, and scrollback replay. Adding it to the nix-configs makes it available as a declarative, reproducible package alongside tmux, with explicit version pinning via a flake input.

## What Changes

- Add `herdr` as a flake input pinned to `github:ogulcancelik/herdr/v0.7.1`
- Apply the herdr overlay (`herdr.overlays.default`) in the home-manager nixpkgs configuration
- Add `pkgs.herdr` to `home.packages` so it is available in the user's PATH
- No tmux changes — herdr is installed alongside the existing tmux setup without modification

## Capabilities

### New Capabilities

- `herdr-terminal-multiplexer`: Install the Herdr terminal multiplexer as a home-manager package via a pinned flake input, available alongside tmux.

### Modified Capabilities

<!-- No existing capabilities are changing -->

## Impact

- **flake.nix**: new `herdr` input, new overlay in `homeConfigurations` pkgs import
- **home-manager/home.nix**: new `herdr` entry in `home.packages`
- **Build**: First build compiles herdr from source (Rust) via the flake; subsequent builds use the Nix store cache
