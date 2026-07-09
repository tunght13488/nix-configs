## Why

AI coding agents waste tokens and time discovering code structure through grep/file-read loops. codebase-memory-mcp indexes codebases into a persistent knowledge graph (158 languages, sub-ms queries, 120x fewer tokens), but pi — the primary agent — has no MCP support. A home-manager module with a pi CLI skill brings the same code-discovery protocol to the agent that's actually in use, while keeping the binary declaratively managed.

## What Changes

- Add `pkgs/codebase-memory-mcp/default.nix` — fetches the pre-built static binary from GitHub releases (v0.9.0, portable Linux amd64)
- Add `modules/home-manager/codebase-memory-mcp.nix` — declarative module with `mkEnableOption`, installs the package and writes the pi skill
- Add a pi skill at `~/.pi/agent/skills/codebase-memory/SKILL.md` — teaches the agent to use the CLI tools for code discovery, matching the same workflow guidance that the native `install` command provides to Claude Code (decision matrix, exploration workflows, gotchas)
- Import the module in `home-manager/home.nix`

## Capabilities

### New Capabilities

- `codebase-memory-mcp`: High-performance code intelligence via a pre-built static binary, home-manager module, and pi skill. The agent discovers code structure through CLI knowledge-graph queries instead of grep/file-read loops.

### Modified Capabilities

*(none)*

## Impact

- New files: `pkgs/codebase-memory-mcp/default.nix`, `modules/home-manager/codebase-memory-mcp.nix`, pi skill content
- Modified: `home-manager/home.nix` (import the module), `flake.nix` (expose the package if desired)
- Dependencies: `fetchurl` for GitHub releases binary, no new flake inputs
- Cache: binary writes indexes to `~/.cache/codebase-memory-mcp/` (not Nix-managed)
