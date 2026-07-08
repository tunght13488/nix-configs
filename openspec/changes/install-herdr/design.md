## Context

The nix-configs flake currently provides tmux as the terminal multiplexer via `home-manager/tmux.nix`. Herdr (github.com/ogulcancelik/herdr, v0.7.1) is a newer terminal multiplexer designed specifically for AI coding agent workflows. It is available in nixpkgs-unstable but not in nixos-25.11 (which this config follows). The user wants to install it declaratively alongside tmux without changing tmux configuration.

The herdr project provides a flake at `github:ogulcancelik/herdr` that exposes:
- `packages.<system>.herdr` — the main package built from `nix/package.nix`
- `overlays.default` — adds `herdr` to the package set
- `apps.default`, `devShells.default`, `checks.herdr`

## Goals / Non-Goals

**Goals:**
- Add herdr as a pinned flake input (`v0.7.1`) for explicit version control
- Make `pkgs.herdr` available in home-manager via the herdr overlay
- Include `herdr` in `home.packages` so it appears on PATH
- Verify the build succeeds with `make home-build`

**Non-Goals:**
- Do NOT add herdr configuration (no `xdg.configFile` or theme/keybinding setup)
- Do NOT modify or remove tmux
- Do NOT add herdr to NixOS system packages (user-level only)
- Do NOT add herdr to devShells

## Decisions

### Decision 1: Flake input vs nixpkgs-unstable

**Chosen**: Add herdr as a dedicated flake input (`github:ogulcancelik/herdr/v0.7.1`).

**Alternatives considered**:
- `pkgs.unstable.herdr` — already available and cached. Rejected because the user wants explicit version pinning via flake input.
- Shell installer (`curl | sh`) — non-declarative, won't survive rebuilds. Rejected outright.

**Rationale**: A dedicated flake input gives the user direct control over which herdr version they use. Updates are explicit (change the tag, run `nix flake update herdr`).

### Decision 2: nixpkgs follows

**Chosen**: Do NOT override herdr's nixpkgs with `follows`. Let herdr use its own nixpkgs (`nixos-unstable`).

**Alternatives considered**:
- `herdr.inputs.nixpkgs.follows = "nixpkgs-unstable"` — would reduce duplicate nixpkgs copies but could break if herdr's build depends on specific unstable revisions. Rejected for stability.
- `herdr.inputs.nixpkgs.follows = "nixpkgs"` — would pin herdr to nixos-25.11, which lacks dependencies for a March-2026 Rust project. Rejected as likely broken.

**Rationale**: Letting herdr use its own nixpkgs is the safest default. If both resolve to the same nixpkgs revision, the Nix store deduplicates automatically. This can be optimized later if needed.

### Decision 3: Overlay placement

**Chosen**: Add `herdr.overlays.default` only to the `homeConfigurations` pkgs import (not to `nixosConfigurations` or `devShells`).

**Rationale**: Herdr is a user-facing terminal tool. It has no use in system services or project dev shells. Keeping the overlay scoped to home-manager avoids unnecessary rebuilds.

## Risks / Trade-offs

- **[Compilation time]** Herdr builds from source via the flake's `nix/package.nix`. The first `home-manager switch` will compile a Rust project. Mitigation: Nix caches the result; subsequent builds reuse the store path.
- **[No binary cache]** The `github:ogulcancelik/herdr` flake is not in the public Nix cache. Each machine must build locally. Mitigation: This is a single-machine config; the build happens once.
- **[nixpkgs duplication]** Herdr's flake pins its own nixpkgs-unstable, which may differ from this repo's `nixpkgs-unstable` input. Mitigation: The Nix store deduplicates when revisions match. If duplication becomes a concern, consider `follows` later.
