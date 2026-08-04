## MODIFIED Requirements

### Requirement: Herdr agent skill derivation sources from flake input
The system SHALL provide a Nix derivation (`pkgs/herdr-agent-files.nix`) that copies `SKILL.md` from `${inputs.herdr.outPath}/skills/herdr/SKILL.md` into a structured output directory for agent consumption.

#### Scenario: Derivation succeeds when SKILL.md exists in flake source
- **WHEN** the derivation is built and `${inputs.herdr.outPath}/skills/herdr/SKILL.md` exists
- **THEN** the output contains `$out/.pi/skills/herdr/SKILL.md` and `$out/.opencode/skills/herdr/SKILL.md` with identical content to the flake source

#### Scenario: Derivation follows the openspec-agent-files pattern
- **WHEN** the derivation is built
- **THEN** it uses `runCommand` (or equivalent) with the same structural conventions as `pkgs/openspec-agent-files.nix`