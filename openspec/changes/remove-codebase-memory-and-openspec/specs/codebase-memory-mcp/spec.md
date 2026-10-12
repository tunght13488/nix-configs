# Spec Delta

## REMOVED Requirements

### Requirement: Binary is available as a Nix package
**Reason**: codebase-memory-mcp is no longer used; the package, module, and skill are removed from the flake entirely.
**Migration**: Remove `pkgs/codebase-memory-mcp/`, its entry in `pkgs/default.nix`, and all consumers. No replacement; standard grep/glob/read tools cover code discovery.

### Requirement: Home-manager module installs the binary
**Reason**: The module `modules/home-manager/codebase-memory-mcp.nix` is deleted along with its export in `modules/home-manager/default.nix`, its import in `home-manager/home.nix`, and the `programs.codebase-memory-mcp.enable` flag in `home-manager/ai.nix`.
**Migration**: After `make home`, the `codebase-memory-mcp` binary is removed from the user profile. No replacement.

### Requirement: Package bundles the pi skill file
**Reason**: The package is deleted; there is no output to bundle a skill into.
**Migration**: None. The skill file `pkgs/codebase-memory-mcp/skill.md` is deleted with the package.

### Requirement: Pi skill is symlinked from the package
**Reason**: The module that created the `~/.pi/agent/skills/codebase-memory/SKILL.md` symlink is deleted.
**Migration**: home-manager removes the managed symlink on the next activation. No manual cleanup needed.

### Requirement: Pi skill teaches code discovery protocol
**Reason**: The skill file no longer exists; agents fall back to standard file/search tools for code discovery.
**Migration**: None.

### Requirement: Module can be toggled independently
**Reason**: The module no longer exists, so there is nothing to toggle.
**Migration**: None.
