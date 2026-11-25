# Spec Delta

## ADDED Requirements

### Requirement: Read-only parent Git metadata
Pi-box SHALL grant read-only access to external parent `.git` metadata required by the workspace when it is not already covered by an existing worktree metadata grant. It SHALL NOT grant write access to that metadata or access to unrelated parent paths.

#### Scenario: Parent Git metadata is readable
- **WHEN** a project workspace is nested in a repository and its `.git` metadata is outside the workspace and not already granted
- **THEN** sandboxed Pi can read that metadata

#### Scenario: Parent Git metadata remains read-only
- **WHEN** a process in that sandbox attempts to write to the external parent `.git` metadata
- **THEN** the write is denied

#### Scenario: Unrelated parent paths remain unavailable
- **WHEN** a process in that sandbox attempts to read an unrelated path outside the workspace and the granted Git metadata
- **THEN** the read is denied
