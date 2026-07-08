## Context

Herdr is consumed via a flake input pinned to a git tag (`github:ogulcancelik/herdr/v0.7.1`). The overlay `herdr.overlays.default` injects the herdr package into nixpkgs for home-manager. The config is managed via a TOML bootstrap in `home-manager/herdr.nix`.

The upstream released v0.7.2 (features) and v0.7.3 (bugfixes) on 2026-07-07. This change bumps the pin from v0.7.1 to v0.7.3.

## Goals / Non-Goals

**Goals:**
- Update the herdr flake input ref from `v0.7.1` to `v0.7.3`
- Verify the build succeeds with `make home-build`

**Non-Goals:**
- Adopting new v0.7.2 features (shell completions, sidebar_collapsed_mode) in the config
- Changing the overlay or package installation approach
- Modifying the herdr config TOML baseline

## Decisions

**Decision: Bump directly to v0.7.3 (skip v0.7.2)**

Rationale: v0.7.3 is a pure bugfix on top of v0.7.2. There is no reason to pin to v0.7.2 when a bugfix release is available that includes all v0.7.2 features plus fixes. The upstream does not maintain separate release branches — v0.7.3 supersedes v0.7.2.

**Decision: No config changes**

Rationale: v0.7.2's new config keys (`ui.sidebar_collapsed_mode`) have sensible defaults matching current behavior. Shell completions and other new CLI features are additive and don't require config migration. Adopting new features is tracked separately.

## Risks / Trade-offs

- **Risk**: The herdr overlay or package derivation changed between v0.7.1 and v0.7.3 in a way that breaks the build → **Mitigation**: `make home-build` catches this. The overlay is part of the upstream repo and tested by their CI.
