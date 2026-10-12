# Proposal

## Why

The codebase-memory-mcp skill and the global OpenSpec integration (agent skills, prompt templates, slash commands, and the CLI itself) are no longer used. Keeping them means maintaining a pinned-source derivation, a version-locked overlay override, a custom home-manager module, and ~50 home-manager-managed symlink entries for tooling that provides no value.

## What Changes

- **BREAKING** Remove the `codebase-memory` pi skill and the `codebase-memory-mcp` binary: delete the home-manager module (`modules/home-manager/codebase-memory-mcp.nix`), the package (`pkgs/codebase-memory-mcp/`), and all references (module export, `pkgs/default.nix` entry, import in `home-manager/home.nix`, enable flag in `home-manager/ai.nix`).
- **BREAKING** Remove all global OpenSpec agent integration files: delete `home-manager/openspec.nix`, which links 12 workflow skills + 12 prompts into `~/.pi/agent/` and 12 skills + 12 commands into `~/.config/opencode/`.
- **BREAKING** Remove the OpenSpec CLI: drop `unstable.openspec` from `home.packages` and delete the `openspec` version-pin override in the `unstable-packages` overlay.
- Remove the now-unused agent-files generation pipeline: delete `pkgs/openspec-agent-files.nix` and `pkgs/generate-agent-files.mjs`, and drop the `openspecAgentFiles` attribute from the `additions` overlay.
- Clean up the commented-out OpenSpec entries in the global git ignore list in `home-manager/git.nix`.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `codebase-memory-mcp`: entire capability removed — the Nix package, home-manager module, and pi skill no longer exist.
- `openspec-global-skills`: entire capability removed — no OpenSpec skills, prompts, or commands are linked into global Pi/OpenCode config directories.
- `openspec-agent-generation`: entire capability removed — the derivation that generates agent integration files from pinned upstream source no longer exists.

## Impact

- **Deleted files**: `modules/home-manager/codebase-memory-mcp.nix`, `pkgs/codebase-memory-mcp/` (`default.nix`, `skill.md`), `home-manager/openspec.nix`, `pkgs/openspec-agent-files.nix`, `pkgs/generate-agent-files.mjs`.
- **Edited files**: `modules/home-manager/default.nix` (drop module export), `pkgs/default.nix` (drop package), `home-manager/home.nix` (drop module import, `./openspec.nix` import, `unstable.openspec` package), `home-manager/ai.nix` (drop enable flag), `overlays/default.nix` (drop `openspecAgentFiles` and the openspec override), `home-manager/git.nix` (drop commented OpenSpec ignore entries).
- **User environment**: after `make home`, `codebase-memory-mcp` and `openspec` disappear from PATH; `~/.pi/agent/skills/openspec-*`, `~/.pi/agent/skills/codebase-memory`, `~/.pi/agent/prompts/opsx-*.md`, `~/.config/opencode/skills/openspec-*`, and `~/.config/opencode/commands/opsx-*.md` symlinks are removed by home-manager.
- **Assumptions**: the project-level `openspec/` directory in this repo (specs, changes, archive) is kept — the request targets the *global* agent integration and CLI only. Other specs (hyprland, herdr, etc.) are unaffected. The `herdrAgentFiles` overlay attribute and `herdr` package follow the same pattern but are explicitly out of scope.
