# Spec Delta

## REMOVED Requirements

### Requirement: OpenSpec skills available globally for Pi
**Reason**: The global OpenSpec workflow integration is no longer used; `home-manager/openspec.nix` (which links the 12 skills and 12 prompts into `~/.pi/agent/`) is deleted.
**Migration**: home-manager removes the managed symlinks on the next activation. If OpenSpec is needed in a project again, run `openspec init` there for project-local integration.

### Requirement: OpenSpec skills available globally for OpenCode
**Reason**: Same removal — the `xdg.configFile` entries linking skills and commands into `~/.config/opencode/` are deleted with `home-manager/openspec.nix`.
**Migration**: home-manager removes the managed symlinks on the next activation. No replacement.

### Requirement: Files match generated OpenSpec output
**Reason**: Neither the generated files nor the consumers remain; the generation derivation (`pkgs/openspec-agent-files.nix`) and the linking module (`home-manager/openspec.nix`) are both deleted.
**Migration**: None.

### Requirement: Individual file linking
**Reason**: No OpenSpec files are linked into global agent directories anymore.
**Migration**: None. Other global skills (e.g. herdr) are unaffected and continue to use the same per-file linking pattern.
