## Why

Herdr v0.8.0 ships the `herdr --skill` feature (printing the bundled agent skill), a GitHub organization migration from `ogulcancelik/herdr` to `herdrdev/herdr`, and a relocated `SKILL.md` (now at `skills/herdr/SKILL.md` instead of the repo root). Our current packaging symlinks `${herdrSrc}/SKILL.md` from the repo root, which breaks against v0.8.0; the flake input URL also references the old organization. Updating now keeps the local toolchain current with upstream fixes and restores a working agent-skill bootstrap.

## What Changes

- Bump `inputs.herdr.url` from `github:ogulcancelik/herdr/v0.7.5` to `github:herdrdev/herdr/v0.8.0` (organization migration)
- Update `flake.lock` via `nix flake lock --update-input herdr`
- **BREAKING** (packaging fix): Update `pkgs/herdr-agent-files.nix` to source `SKILL.md` from `${herdrSrc}/skills/herdr/SKILL.md` instead of `${herdrSrc}/SKILL.md`, since v0.8.0 moved the skill file out of the repo root
- Verify `herdr --skill` works against the bundled skill shipped by the v0.8.0 Nix package (`nix/package.nix` now bundles `skills/herdr/SKILL.md`)
- Verify the existing config baseline in `home-manager/herdr.nix` does not introduce unknown config keys (v0.8.0 adds optional `ui.pane_scrollbars` and `ui.tab_bar_position`; neither is adopted into the baseline now)

## Capabilities

### New Capabilities
<!-- No new capabilities introduced — this is a version bump of an existing dependency plus a packaging fix -->

### Modified Capabilities
- `herdr-terminal-multiplexer`: Update the pinned flake input from `v0.7.5` at `ogulcancelik/herdr` to `v0.8.0` at `herdrdev/herdr`. The existing requirements for PATH availability, flake input pinning, overlay application, declarative config, module conventions, and tmux coexistence remain valid.
- `herdr-agent-skill`: Update the agent-skill derivation source path from `${herdrSrc}/SKILL.md` (repo root) to `${herdrSrc}/skills/herdr/SKILL.md`, matching the v0.8.0 skill relocation. All other skill derivation, overlay, home-manager linking, and global availability requirements remain valid.

## Impact

- `flake.nix` — URL change in `inputs.herdr` (organization + tag)
- `flake.lock` — regenerated herdr input lock entry
- `pkgs/herdr-agent-files.nix` — SKILL.md source path change (root → `skills/herdr/SKILL.md`); required to keep the derivation building against v0.8.0
- `home-manager/herdr.nix` — no code changes needed (config baseline remains compatible; new optional keys are not adopted)
- `openspec/specs/herdr-terminal-multiplexer/spec.md` — delta spec updates the version and URL reference
- `openspec/specs/herdr-agent-skill/spec.md` — delta spec updates the SKILL.md source path from the repo root to `skills/herdr/SKILL.md`