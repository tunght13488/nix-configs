## MODIFIED Requirements

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
