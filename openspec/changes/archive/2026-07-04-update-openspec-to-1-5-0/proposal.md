## Why

OpenSpec 1.5.0 introduces the Stores beta — a simpler model for organizing specs and changes across projects, replacing the retired workspace/initiative system. The current 1.4.1 CLI is incompatible with the new store, reference, target, doctor, and context commands. Upgrading now unblocks use of stores for cross-repo coordination.

## What Changes

- Override `unstable.openspec` to build from the v1.5.0 source tarball instead of the 1.4.1 source in nixpkgs-unstable
- Update the `pnpmDeps` hash to match 1.5.0 dependencies
- Regenerate agent files (Pi skills/prompts, OpenCode skills/commands) via `openspec init --tools pi,opencode --force` and update the checked-in copies in `pkgs/openspec-agent-files/`
- No changes to `openspec/config.yaml` — the `spec-driven` schema and existing project configuration remain valid

## Capabilities

### New Capabilities

None. This is a tool version bump, not a new system capability.

### Modified Capabilities

None. The `openspec-global-skills` spec defines the mechanism (files in `~/.pi/agent/skills/`), not the specific content version, and this change regenerates the same set of files through the same mechanism.

## Impact

- `overlays/default.nix`: the `unstable-packages` overlay (or a new source override) will override `openspec.src` and `openspec.pnpmDeps`
- `pkgs/openspec-agent-files/`: all 11 skill directories and 11 prompt/command files regenerated
- `flake.lock`: may update if `nix flake update` is run (not strictly required if only the source override changes)
- No runtime config changes; `home-manager/home.nix` (`unstable.openspec`) unchanged
