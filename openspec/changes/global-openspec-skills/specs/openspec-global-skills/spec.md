## ADDED Requirements

### Requirement: OpenSpec skills available globally for Pi
The system SHALL make OpenSpec workflow skills available to Pi in all project directories via home-manager-managed files in `~/.pi/agent/skills/`.

#### Scenario: Pi discovers OpenSpec skills from global location
- **WHEN** Pi starts in any project directory
- **THEN** the OpenSpec skills (apply, archive, explore, propose) are listed in the available skills summary and can be invoked

#### Scenario: OpenSpec prompts available globally for Pi
- **WHEN** Pi starts in any project directory
- **THEN** the OpenSpec prompt templates (`/opsx-apply`, `/opsx-archive`, `/opsx-explore`, `/opsx-propose`) are available as slash commands

### Requirement: OpenSpec skills available globally for OpenCode
The system SHALL make OpenSpec workflow skills available to OpenCode in all project directories via home-manager-managed files in `~/.config/opencode/skills/`.

#### Scenario: OpenCode discovers OpenSpec skills from global location
- **WHEN** OpenCode starts in any project directory
- **THEN** the OpenSpec skills (apply, archive, explore, propose) are available to the agent

#### Scenario: OpenSpec commands available globally for OpenCode
- **WHEN** OpenCode starts in any project directory
- **THEN** the OpenSpec command files (`/opsx-apply`, `/opsx-archive`, `/opsx-explore`, `/opsx-propose`) are available

### Requirement: Files match generated OpenSpec output
The system SHALL store skill, prompt, and command files that match what `openspec init --tools pi,opencode --force` produces, to ensure compatibility with the installed OpenSpec CLI.

#### Scenario: Files are regenerated when openspec updates
- **WHEN** the openspec CLI version is updated in the flake lock
- **THEN** run `openspec init` outside Nix and update the checked-in files in `pkgs/openspec-agent-files/`

### Requirement: Individual file linking
The system SHALL link individual files to global agent directories rather than replacing entire directories, to coexist with other globally installed skills.

#### Scenario: Non-OpenSpec skills preserved
- **WHEN** another global skill is installed in `~/.pi/agent/skills/` alongside OpenSpec skills
- **THEN** both skills are available to the agent
