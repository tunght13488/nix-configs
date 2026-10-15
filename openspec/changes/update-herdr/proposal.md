# Proposal

## Why

Herdr v0.9.5 was released upstream (2026-10-14) as a hotfix for v0.9.4, which this config currently pins. The release fixes prefix shortcuts breaking when the terminal sends the next key as plain text — this affects Ghostty `text:` keybinds that send the prefix and a key together, and this machine's terminal is Ghostty. It also removes the Codex turn hooks that caused a "clamping Interrupt hook timeout" warning, and shows Claude Code questions as blocked in named sessions.

## What Changes

- Bump the herdr flake input in `flake.nix` from `github:herdrdev/herdr/v0.9.4` to `github:herdrdev/herdr/v0.9.5`.
- Update `flake.lock` for the `herdr` input only (no other inputs touched).
- No changes to `home-manager/herdr.nix`, `pkgs/herdr-agent-files.nix`, or the overlay wiring — v0.9.5 keeps `skills/herdr/SKILL.md` at the same path (verified against the v0.9.5 tag), and the v0.9.5 release notes rename or remove no config keys used in the generated `config.toml` baseline.

## Capabilities

### New Capabilities

(None)

### Modified Capabilities

- `herdr-terminal-multiplexer`: the "Herdr is pinned via a flake input" requirement changes the pinned tag from `v0.9.4` to `v0.9.5`. All other requirements (overlay application, config.toml management, module placement, tmux coexistence) are unchanged.

## Impact

- **Code**: `flake.nix` (one-line URL change), `flake.lock` (herdr input rev/tag).
- **Dependencies**: herdr v0.9.4 → v0.9.5. Hotfix release scope per upstream release notes; no breaking changes to the config surface.
- **Systems**: home-manager configuration `tung@nixos-vmware` (herdr is installed via `home.packages`); verified with `make home-build`. The user runs `make home` to apply.
- **Behavior**: upstream v0.9.5 no longer installs Codex turn hooks; users with an existing Codex integration are told by upstream to run `herdr integration install codex` once to refresh it. No action needed in this repo (the integration is user-level state, not Nix-managed), but worth knowing if Codex status detection looks stale after the update.
- **Not affected**: `herdr-agent-skill` capability (SKILL.md path unchanged in v0.9.5), tmux setup, herdr config.toml bootstrap.
