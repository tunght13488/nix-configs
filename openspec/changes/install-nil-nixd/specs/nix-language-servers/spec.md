## ADDED Requirements

### Requirement: System provides nil
The system SHALL make the `nil` Nix language server executable available in the global PATH.

#### Scenario: nil is executable
- **WHEN** a user or process runs `nil --version`
- **THEN** the command exits successfully and prints the version of nil

### Requirement: System provides nixd
The system SHALL make the `nixd` Nix language server executable available in the global PATH.

#### Scenario: nixd is executable
- **WHEN** a user or process runs `nixd --version`
- **THEN** the command exits successfully and prints the version of nixd
