# Spec Delta

## REMOVED Requirements

### Requirement: Derivation fetches OpenSpec source at pinned version
**Reason**: The OpenSpec CLI and its global agent integration are removed; there is no consumer for generated agent files, so `pkgs/openspec-agent-files.nix` is deleted along with the `openspecAgentFiles` attribute in the `additions` overlay.
**Migration**: None. The `herdrAgentFiles` attribute in the same overlay follows the same pattern and is kept.

### Requirement: Build script generates pi prompt templates
**Reason**: The build script `pkgs/generate-agent-files.mjs` is deleted with its derivation.
**Migration**: None.

### Requirement: Build script generates pi agent skills
**Reason**: The build script and derivation are deleted; no pi skills are generated.
**Migration**: None.

### Requirement: Build script generates opencode slash commands
**Reason**: The build script and derivation are deleted; no opencode commands are generated.
**Migration**: None.

### Requirement: Build script generates opencode agent skills
**Reason**: The build script and derivation are deleted; no opencode skills are generated.
**Migration**: None.

### Requirement: Derivation output matches home-manager consumer expectations
**Reason**: The consumer (`home-manager/openspec.nix`) and the derivation are both deleted.
**Migration**: None.

### Requirement: Version update is a single-line change
**Reason**: There is no pinned OpenSpec version left to update — the derivation and the separate `openspec` override in the `unstable-packages` overlay are both removed.
**Migration**: None.
