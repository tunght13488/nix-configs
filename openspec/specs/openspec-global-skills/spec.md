## Requirements

### Requirement: OpenSpec skills available globally for Pi
The system SHALL make all OpenSpec experimental workflow skills available to Pi in all project directories via home-manager-managed files in `~/.pi/agent/skills/`.

#### Scenario: Pi discovers OpenSpec skills from global location
- **WHEN** Pi starts in any project directory
- **THEN** all 11 OpenSpec workflow skills (apply, archive, bulk-archive, continue, explore, ff, new, onboard, propose, sync, verify) are listed in the available skills summary and can be invoked

#### Scenario: OpenSpec prompts available globally for Pi
- **WHEN** Pi starts in any project directory
- **THEN** all 11 OpenSpec prompt templates (`/opsx-apply`, `/opsx-archive`, `/opsx-bulk-archive`, `/opsx-continue`, `/opsx-explore`, `/opsx-ff`, `/opsx-new`, `/opsx-onboard`, `/opsx-propose`, `/opsx-sync`, `/opsx-verify`) are available as slash commands

### Requirement: OpenSpec skills available globally for OpenCode
The system SHALL make all OpenSpec experimental workflow skills available to OpenCode in all project directories via home-manager-managed files in `~/.config/opencode/skills/`.

#### Scenario: OpenCode discovers OpenSpec skills from global location
- **WHEN** OpenCode starts in any project directory
- **THEN** all 11 OpenSpec workflow skills (apply, archive, bulk-archive, continue, explore, ff, new, onboard, propose, sync, verify) are available to the agent

#### Scenario: OpenSpec commands available globally for OpenCode
- **WHEN** OpenCode starts in any project directory
- **THEN** all 11 OpenSpec command files (`/opsx-apply`, `/opsx-archive`, `/opsx-bulk-archive`, `/opsx-continue`, `/opsx-explore`, `/opsx-ff`, `/opsx-new`, `/opsx-onboard`, `/opsx-propose`, `/opsx-sync`, `/opsx-verify`) are available

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
