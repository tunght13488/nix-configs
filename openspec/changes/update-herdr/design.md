# Design

## Context

Herdr is consumed via a flake input pinned to a git tag (`github:herdrdev/herdr/v0.9.1`). The overlay `herdr.overlays.default` injects the herdr package into nixpkgs for home-manager. The config is managed via a TOML bootstrap in `home-manager/herdr.nix`.

The upstream released v0.9.2. This change bumps the pin from v0.9.1 to v0.9.2.

## Goals / Non-Goals

**Goals:**
- Update the herdr flake input ref from `v0.9.1` to `v0.9.2`
- Verify the build succeeds with `make home-build`

**Non-Goals:**
- Adopting new features or config options from v0.9.2 in the herdr config
- Changing the overlay or package installation approach
- Modifying the herdr config TOML baseline

## Decisions

**Decision: Bump directly to v0.9.2**

Rationale: v0.9.2 is the latest release and supersedes v0.9.1. The upstream does not maintain separate release branches — v0.9.2 includes all previous changes.

**Decision: No config changes**

Rationale: Unless v0.9.2 introduces breaking config changes (checked by `make home-build`), the existing config baseline remains valid. Adopting new features is tracked separately.

## Risks / Trade-offs

- **Risk**: The herdr overlay or package derivation changed between v0.9.1 and v0.9.2 in a way that breaks the build → **Mitigation**: `make home-build` catches this. The overlay is part of the upstream repo and tested by their CI.
