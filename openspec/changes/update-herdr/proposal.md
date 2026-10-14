# Proposal

## Why

Herdr v0.9.4 was released upstream (2026-10-13, commit `7e26bad`) while the config pins v0.9.3. The release fixes issues that affect this setup directly: a forwarded SSH agent is no longer polled every second (which could eventually break SSH and Git authentication — this machine authenticates via the 1Password SSH agent), Codex/Pi agent status is recognized in more cases, session saves are written atomically, and the shell that started Herdr no longer takes the server down when closed.

## What Changes

- Bump the herdr flake input in `flake.nix` from `github:herdrdev/herdr/v0.9.3` to `github:herdrdev/herdr/v0.9.4`.
- Update `flake.lock` for the `herdr` input only (no other inputs touched).
- No changes to `home-manager/herdr.nix`, `pkgs/herdr-agent-files.nix`, or the overlay wiring — v0.9.4 keeps `skills/herdr/SKILL.md` at the same path (verified against the v0.9.4 tag), and no config keys used in the generated `config.toml` baseline are renamed or removed in the v0.9.4 release notes.

## Capabilities

### New Capabilities

(None)

### Modified Capabilities

- `herdr-terminal-multiplexer`: the "Herdr is pinned via a flake input" requirement changes the pinned tag from `v0.9.3` to `v0.9.4`. All other requirements (overlay application, config.toml management, module placement, tmux coexistence) are unchanged.

## Impact

- **Code**: `flake.nix` (one-line URL change), `flake.lock` (herdr input rev/tag).
- **Dependencies**: herdr v0.9.3 → v0.9.4. Patch release scope per upstream release notes; no breaking changes to the config surface or the flake's nixpkgs wiring.
- **Systems**: home-manager configuration `tung@nixos-vmware` (herdr is installed via `home.packages`); verified with `make home-build`. The user runs `make home` to apply.
- **Behavior**: upstream v0.9.4 changes server lifecycle on Linux (closing the starting shell no longer stops the server; SIGHUP no longer stops it — `herdr server stop` or SIGTERM is the intended path now). No action needed in this repo, but worth knowing when debugging herdr sessions.
- **Not affected**: `herdr-agent-skill` capability (SKILL.md path unchanged in v0.9.4), tmux setup, herdr config.toml bootstrap.
