## ADDED Requirements

### Requirement: Herdr agent skill derivation sources from flake input
The system SHALL provide a Nix derivation (`pkgs/herdr-agent-files.nix`) that copies `SKILL.md` from `${inputs.herdr.outPath}` into a structured output directory for agent consumption.

#### Scenario: Derivation succeeds when SKILL.md exists in flake source
- **WHEN** the derivation is built and `${inputs.herdr.outPath}/SKILL.md` exists
- **THEN** the output contains `$out/.pi/skills/herdr/SKILL.md` and `$out/.opencode/skills/herdr/SKILL.md` with identical content to the flake source

#### Scenario: Derivation follows the openspec-agent-files pattern
- **WHEN** the derivation is built
- **THEN** it uses `runCommand` (or equivalent) with the same structural conventions as `pkgs/openspec-agent-files.nix`

### Requirement: Herdr skill available globally for Pi
The system SHALL make the herdr agent skill available to Pi in all project directories via a home-manager-managed file at `~/.pi/agent/skills/herdr/SKILL.md`.

#### Scenario: Pi discovers herdr skill from global location
- **WHEN** Pi starts in any project directory
- **THEN** the herdr skill is listed in the available skills summary and can be invoked

#### Scenario: Skill file is a symlink from the Nix store
- **WHEN** home-manager activates
- **THEN** `~/.pi/agent/skills/herdr/SKILL.md` is a symlink sourced from the `herdrAgentFiles` derivation in the Nix store

### Requirement: Herdr skill available globally for OpenCode
The system SHALL make the herdr agent skill available to OpenCode in all project directories via a home-manager-managed file at `~/.config/opencode/skills/herdr/SKILL.md`.

#### Scenario: OpenCode discovers herdr skill from global location
- **WHEN** OpenCode starts in any project directory
- **THEN** the herdr skill is available to the agent

#### Scenario: Skill file is a symlink from the Nix store
- **WHEN** home-manager activates
- **THEN** `~/.config/opencode/skills/herdr/SKILL.md` is a symlink sourced from the `herdrAgentFiles` derivation in the Nix store

### Requirement: Herdr skill exposed via additions overlay
The system SHALL expose the herdr agent files derivation as `herdrAgentFiles` in the `additions` overlay, making it accessible to home-manager modules as `pkgs.herdrAgentFiles`.

#### Scenario: Overlay provides derivation
- **WHEN** any module or package accesses `pkgs.herdrAgentFiles`
- **THEN** it receives the herdr agent files derivation that produces the structured skill output

### Requirement: Skill linking co-located with herdr home-manager module
The system SHALL add skill file linking to the existing `home-manager/herdr.nix` module, keeping all herdr configuration in one file.

#### Scenario: Existing config bootstrapping is undisturbed
- **WHEN** home-manager activates with the updated `herdr.nix`
- **THEN** the config.toml bootstrap logic continues to function unchanged

#### Scenario: Skill files are linked alongside config bootstrapping
- **WHEN** home-manager activates
- **THEN** both the config.toml bootstrap AND the skill symlinks are applied in a single `home-manager switch`
