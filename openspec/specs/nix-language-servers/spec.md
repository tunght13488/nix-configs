### Requirement: User environment provides nil
The user environment SHALL make the `nil` Nix language server executable available in the PATH.

#### Scenario: nil is executable
- **WHEN** a user or process runs `nil --version`
- **THEN** the command exits successfully and prints the version of nil

### Requirement: User environment provides nixd
The user environment SHALL make the `nixd` Nix language server executable available in the PATH.

#### Scenario: nixd is executable
- **WHEN** a user or process runs `nixd --version`
- **THEN** the command exits successfully and prints the version of nixd
