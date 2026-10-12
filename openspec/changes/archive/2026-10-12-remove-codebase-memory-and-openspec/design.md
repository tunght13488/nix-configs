# Design

## Context

The removal surface is spread across four layers of the flake: a home-manager module + enable flag, a custom package, an overlay addition + override, and home-manager imports/package list. All of it is dead weight once the tooling is unused. See proposal.md - Why.

Current state (verified by inspection):

- `programs.codebase-memory-mcp.enable = true` in `home-manager/ai.nix`; module imported in `home-manager/home.nix` and exported from `modules/home-manager/default.nix`; package in `pkgs/codebase-memory-mcp/` exposed via `pkgs/default.nix`.
- `home-manager/openspec.nix` links 48 generated files (12 skills + 12 prompts for Pi, 12 skills + 12 commands for OpenCode) from `pkgs.openspecAgentFiles` into `~/.pi/agent/` and `~/.config/opencode/`.
- `unstable.openspec` is in `home.packages`; the `unstable-packages` overlay pins it to v1.13.2 via `overrideAttrs` with a fetched source and pnpm deps.
- `openspecAgentFiles` is defined inline in the `additions` overlay from `pkgs/openspec-agent-files.nix` + `pkgs/generate-agent-files.mjs`.
- `home-manager/git.nix` has a commented-out OpenSpec block in the global ignore list.

## Goals / Non-Goals

**Goals:**

- Complete removal: after `make home`, no `codebase-memory-mcp` or `openspec` binary in PATH, no openspec/codebase-memory symlinks under `~/.pi/agent/` or `~/.config/opencode/`, and no dangling references in the flake (`rg` finds nothing outside `openspec/` history).
- `make home-build` passes after the edits.

**Non-Goals:**

- Deleting the repo's `openspec/` directory (specs, changes, archive). The request targets the *global* integration and CLI; project-level spec history stays.
- Touching `herdr` / `herdrAgentFiles`, which follow the same pattern but are still used.
- Removing the in-flight change `openspec/changes/add-hyprland-must-have-utilities`.

## Decisions

- **Keep the project-level `openspec/` directory while removing the CLI.** The user asked to remove global skills, prompts, and the CLI — not the spec archive. Consequence: this change (and the other in-flight change) can no longer be archived with a globally installed `openspec` after apply. If archiving is wanted later, use `nix run nixpkgs#openspec -- ...` or a temporary `nix shell`; that is an acceptable trade-off for not carrying the package permanently. Alternative considered: also delete `openspec/` — rejected as out of scope and destructive to spec history.
- **Delete files rather than commenting out or disabling.** The module/package/derivation have no other consumers, and git history preserves them. Alternative considered: keep the module but set `enable = false` — rejected because it keeps the maintenance surface (pinned hashes, version bumps) the change is meant to eliminate.
- **Remove the `unstable-packages` overlay's openspec override entirely** (the whole `openspec = prev'.openspec.overrideAttrs ...` block), not just the `home.packages` entry. The pinned v1.13.2 override only exists to serve the removed CLI and the agent-files derivation.
- **Let home-manager clean up the live symlinks.** All removed files were `home.file`/`xdg.configFile` entries, so `make home` unlinks them automatically; no manual `rm` in `~/` is needed or planned.

## Risks / Trade-offs

- [An openspec reference survives in an uninspected file and breaks evaluation] → Run `rg -n "openspec|codebase-memory"` after edits and `make home-build` before declaring done; `home-manager/git.nix` and comment references in `nixos/configuration.nix`/`home-manager/hyprland.nix` (which point at archived change docs) are the known remaining hits and stay.
- [Something outside the flake references `openspecAgentFiles` or the module] → Both are flake-internal (`inputs.self` exports consumed only by `home-manager/home.nix`); the build will fail loudly if a consumer was missed.
- [Archiving this change later needs the CLI] → Documented above; use `nix run nixpkgs#openspec` ad hoc.
