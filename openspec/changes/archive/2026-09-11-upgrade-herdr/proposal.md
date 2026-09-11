## Why

Herdr v0.9.0 is the latest stable release and we are pinned at v0.8.2. It ships changes directly relevant to this setup: Nix installations now fetch crates through the static CDN (#3505, fixing build download failures), idle scrollback memory compression, client-side terminal rendering, a fix for Oh My Pi briefly reporting idle during scheduled continuations (#2851/#3122 — affects this agent setup), Wayland clipboard freeze fix (#3014), and mouse selection/agent-detection fixes across Pi, Claude Code, Codex, and OpenCode. Updating keeps the local toolchain current with upstream fixes.

## What Changes

- Bump `inputs.herdr.url` from `github:herdrdev/herdr/v0.8.2` to `github:herdrdev/herdr/v0.9.0`
- Update `flake.lock` via `nix flake lock --update-input herdr`
- Verify the existing config baseline in `home-manager/herdr.nix` still parses under v0.9.0 — notably that `one-dark` remains a valid built-in theme name and `ui.toast.delivery = "system"` remains valid (both confirmed present in the v0.9.0 config model source)
- Verify no packaging changes are needed: `skills/herdr/SKILL.md` and `nix/package.nix` paths are unchanged at v0.9.0 (confirmed against the upstream tag); the flake still exposes `overlays.default` and `packages.<system>.herdr`
- Note upstream **BREAKING** changes that do not affect this config: the single-process `--no-session` mode was removed (not used here), and lifecycle event subscriptions now start live rather than replaying (API-client concern only)
- New v0.9.0 config surface (`ui.pane_borders = "always"|"auto"|"off"`, `terminal.kitty_graphics`, sidebar text/metadata color rules, per-mode custom theme overrides, Muse agent detection) is not adopted into the baseline; it remains available for local experimentation via the writable config

## Capabilities

### New Capabilities
<!-- No new capabilities introduced — this is a version bump of an existing dependency -->

### Modified Capabilities
- `herdr-terminal-multiplexer`: Update the pinned flake input tag from `v0.8.2` to `v0.9.0`. The existing requirements for PATH availability, flake input pinning, overlay application, declarative config, module conventions, and tmux coexistence remain valid.

## Impact

- `flake.nix` — tag change in `inputs.herdr.url` (`v0.8.2` → `v0.9.0`)
- `flake.lock` — regenerated herdr input lock entry
- `pkgs/herdr-agent-files.nix` — no changes; the SKILL.md source path (`skills/herdr/SKILL.md`) is unchanged at v0.9.0, and the updated skill content flows through automatically from the bumped flake input
- `home-manager/herdr.nix` — no code changes expected; config baseline compatibility is verified via `herdr config check`
- `openspec/specs/herdr-terminal-multiplexer/spec.md` — delta spec updates the pinned tag reference
