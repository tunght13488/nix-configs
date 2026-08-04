## Why

Herdr v0.7.5 ships critical fixes for Pi lifecycle reporting (settled events preventing mid-turn idle state), agent prompt stall detection, and config validation — all directly relevant to daily agent-driven workflows. It also introduces new config options (`ui.sidebar_start_collapsed`, `ui.prompt_new_workspace_name`) and a breaking plugin storage change. Updating keeps the local toolchain current with upstream fixes and enables future adoption of new features.

## What Changes

- Bump `inputs.herdr.url` from `github:ogulcancelik/herdr/v0.7.4` to `github:ogulcancelik/herdr/v0.7.5`
- Update `flake.lock` via `nix flake lock --update-input herdr`
- Verify the bundled SKILL.md from the new flake source still resolves correctly via `pkgs/herdr-agent-files.nix`
- Verify the config baseline in `home-manager/herdr.nix` does not introduce unknown keys (v0.7.5 adds `herdr config check` — new keys like `ui.sidebar_start_collapsed` and `ui.prompt_new_workspace_name` are optional and not added to the baseline now)

## Capabilities

### New Capabilities
<!-- No new capabilities introduced — this is a version bump of an existing dependency -->

### Modified Capabilities
- `herdr-terminal-multiplexer`: Update the pinned flake input from v0.7.4 to v0.7.5. All existing requirements remain valid; no config, overlay, or packaging changes needed.

## Impact

- `flake.nix` — one-line URL change in `inputs.herdr`
- `flake.lock` — regenerated herdr input lock entry
- `home-manager/herdr.nix` — no code changes needed (config baseline remains compatible)
- `pkgs/herdr-agent-files.nix` — no code changes needed (SKILL.md path unchanged)
- `openspec/specs/herdr-terminal-multiplexer/spec.md` — delta spec updates the version reference
