# Spec Delta

## ADDED Requirements

### Requirement: GitHub SCP-style SSH remotes work without SSH credentials

Git operations in the sandbox that target GitHub using SCP-style SSH URLs SHALL transparently use HTTPS and the existing in-container GitHub credential helper. This SHALL NOT require mounting SSH identities or changing the repository's configured remote URL.

#### Scenario: Fetch through a GitHub SSH-form remote
- **WHEN** `git fetch`, `git ls-remote`, or a clone targets `git@github.com:ORG/REPO.git` and the sandbox has a valid GitHub token
- **THEN** the operation succeeds over HTTPS using the in-container credential helper without an SSH agent

#### Scenario: Existing remote configuration remains unchanged
- **WHEN** a Git operation uses an SSH-form GitHub remote in the sandbox
- **THEN** the configured remote URL remains `git@github.com:ORG/REPO.git`

#### Scenario: Other SSH hosts are not rewritten
- **WHEN** a Git operation targets an SSH URL for a host other than `github.com`
- **THEN** the sandbox does not rewrite that URL as a GitHub HTTPS URL
