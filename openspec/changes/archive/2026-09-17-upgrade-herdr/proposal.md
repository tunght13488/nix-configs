## Why

The configuration currently pins Herdr at v0.9.0, while v0.9.1 is the latest stable release. Updating the pinned tool keeps the installed terminal multiplexer and the agent skill sourced from the same flake input current with upstream fixes for SSH sessions, terminal input/rendering, selection, and Pi/OpenCode agent detection.

## What Changes

- Bump `inputs.herdr.url` from `github:herdrdev/herdr/v0.9.0` to `github:herdrdev/herdr/v0.9.1`.
- Regenerate the Herdr lock entry and any required transitive input locks with `nix flake lock --update-input herdr`.
- Verify that the existing `herdr` package, overlay, writable config bootstrap, and agent-skill links continue to work with v0.9.1.
- Validate the existing Herdr configuration and make only minimal compatibility corrections if v0.9.1 rejects an existing setting.
- Keep the current baseline configuration and tmux coexistence unchanged; do not adopt unrelated new Herdr configuration or remote-machine policy as part of this dependency update.

## Capabilities

### New Capabilities

<!-- No new capabilities are introduced. -->

### Modified Capabilities

- `herdr-terminal-multiplexer`: Update the pinned Herdr release from v0.9.0 to v0.9.1 while preserving PATH availability, the home-manager overlay, declarative config bootstrap, and tmux coexistence requirements.

## Impact

- `flake.nix` — Herdr input tag.
- `flake.lock` — Herdr revision and any transitive inputs selected by the lock update.
- `openspec/specs/herdr-terminal-multiplexer/spec.md` — delta to the pinned release requirement.
- `home-manager/herdr.nix` and `pkgs/herdr-agent-files.nix` — compatibility/build verification; changes are not expected unless the upstream release changes the existing config or skill source paths.
- Home-manager evaluation and the local Herdr binary — must be built and checked before activation.
