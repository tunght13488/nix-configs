## Why

Herdr v0.8.2 is the latest stable release (2026-08-19) and we are pinned at v0.8.0. It ships a large set of fixes relevant to daily use — CPU regressions in busy multi-pane sessions, foreground typing latency, agent state detection fixes (Pi, Claude Code, OpenCode), and an updated bundled agent skill that now matches the stable CLI and lifecycle behavior. Updating keeps the local toolchain current with upstream fixes.

## What Changes

- Bump `inputs.herdr.url` from `github:herdrdev/herdr/v0.8.0` to `github:herdrdev/herdr/v0.8.2`
- Update `flake.lock` via `nix flake lock --update-input herdr`
- Verify the existing config baseline in `home-manager/herdr.nix` still parses under v0.8.2 — notably that `one-dark` remains a valid built-in theme name, since `herdr config check` now rejects unknown built-in theme names (#2452)
- Verify no packaging changes are needed: `skills/herdr/SKILL.md` and `nix/package.nix` paths are unchanged at v0.8.2 (confirmed against the upstream tag)
- New optional config keys (`ui.window_title`, `keys.move_tab_previous/next`, `keys.resize_pane_*`, `ui.pane_outer_borders`, tab-bar status entries, `theme.custom.sidebar_bg`/`selection_bg`) are not adopted into the baseline; they remain available for local experimentation via the writable config

## Capabilities

### New Capabilities
<!-- No new capabilities introduced — this is a version bump of an existing dependency -->

### Modified Capabilities
- `herdr-terminal-multiplexer`: Update the pinned flake input tag from `v0.8.0` to `v0.8.2`. The existing requirements for PATH availability, flake input pinning, overlay application, declarative config, module conventions, and tmux coexistence remain valid.

## Impact

- `flake.nix` — tag change in `inputs.herdr.url` (`v0.8.0` → `v0.8.2`)
- `flake.lock` — regenerated herdr input lock entry
- `pkgs/herdr-agent-files.nix` — no changes; the SKILL.md source path (`skills/herdr/SKILL.md`) is unchanged at v0.8.2, and the updated skill content flows through automatically from the bumped flake input
- `home-manager/herdr.nix` — no code changes expected; config baseline compatibility is verified via `herdr config check`
- `openspec/specs/herdr-terminal-multiplexer/spec.md` — delta spec updates the pinned tag reference
