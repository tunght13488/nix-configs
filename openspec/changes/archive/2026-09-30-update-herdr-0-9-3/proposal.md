# Proposal

## Why

Herdr v0.9.3 is a hotfix release for the currently pinned v0.9.2. It fixes broken terminal input handling in panes: Escape-followed-by-key shortcuts (Option+Left/Right/Backspace word movement/deletion from Ghostty and iTerm2 presets, Escape-based Shift+Enter newline in Claude Code) and Alt+[ key merging. These regressions affect daily terminal use, so the pin should move to the hotfix.

## What Changes

- Bump the herdr flake input in `flake.nix` from `github:herdrdev/herdr/v0.9.2` to `github:herdrdev/herdr/v0.9.3`.
- Update `flake.lock` for the `herdr` input only (no other inputs touched).
- No changes to `home-manager/herdr.nix`, `pkgs/herdr-agent-files.nix`, or the overlay wiring — v0.9.3 keeps `skills/herdr/SKILL.md` at the same path (verified against the v0.9.3 tag), so the agent-skill derivation is unaffected.

## Capabilities

### New Capabilities

(None)

### Modified Capabilities

- `herdr-terminal-multiplexer`: the "Herdr is pinned via a flake input" requirement changes the pinned tag from `v0.9.2` to `v0.9.3`. All other requirements (overlay application, config.toml management, module placement, tmux coexistence) are unchanged.

## Impact

- **Code**: `flake.nix` (one-line URL change), `flake.lock` (herdr input rev/tag).
- **Dependencies**: herdr v0.9.2 → v0.9.3. Hotfix scope per upstream release notes; no breaking changes, no nixpkgs follows changes.
- **Systems**: home-manager configuration `tung@nixos-vmware` (herdr is installed via `home.packages`); verified with `make home-build`. The user runs `make home` to apply.
- **Not affected**: `herdr-agent-skill` capability (SKILL.md path unchanged in v0.9.3), tmux setup, herdr config.toml bootstrap.
