## Context

Herdr is consumed via a flake input pinned to a git tag (`github:ogulcancelik/herdr/v0.7.3`). The overlay `herdr.overlays.default` injects the herdr package into nixpkgs for home-manager. The config is managed via a TOML bootstrap in `home-manager/herdr.nix`.

The upstream released v0.7.4. This change bumps the pin from v0.7.3 to v0.7.4.

## Goals / Non-Goals

**Goals:**
- Update the herdr flake input ref from `v0.7.3` to `v0.7.4`
- Verify the build succeeds with `make home-build`

**Non-Goals:**
- Adopting new features or config options from v0.7.4 in the herdr config
- Changing the overlay or package installation approach
- Modifying the herdr config TOML baseline

## Decisions

**Decision: Bump directly to v0.7.4**

Rationale: v0.7.4 is the latest release and supersedes v0.7.3. The upstream does not maintain separate release branches — v0.7.4 includes all previous changes.

**Decision: No config changes**

Rationale: Unless v0.7.4 introduces breaking config changes (checked by `make home-build`), the existing config baseline remains valid. Adopting new features is tracked separately.

## Risks / Trade-offs

- **Risk**: The herdr overlay or package derivation changed between v0.7.3 and v0.7.4 in a way that breaks the build → **Mitigation**: `make home-build` catches this. The overlay is part of the upstream repo and tested by their CI.
