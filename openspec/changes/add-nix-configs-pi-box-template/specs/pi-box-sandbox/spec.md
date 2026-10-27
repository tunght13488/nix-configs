# Spec Delta

## MODIFIED Requirements

### Requirement: Per-project opt-in grants via manifest

A per-project manifest (`pi-box.toml`) SHALL be the only mechanism for granting resources beyond the default set. Supported grants SHALL be: published ports, extra environment variables, extra read-only mounts, named Docker volumes, disabling the `~/.config/gh` mount, and privileged container mode. Grants not declared in the manifest SHALL NOT be present.

#### Scenario: Host database access
- **WHEN** the manifest sets `DB_HOST=host.docker.internal` and the sandbox runs the project's feature tests
- **THEN** the tests connect to the host's MySQL and no database credentials are duplicated in the manifest

#### Scenario: Dropping the GitHub identity
- **WHEN** the manifest disables the gh mount
- **THEN** `~/.config/gh` is not present inside the sandbox

#### Scenario: Named volume persists across runs
- **WHEN** the manifest declares `volumes = ["pi-m2-example:/root/.m2"]` and a sandbox run writes files under `/root/.m2`
- **THEN** a later sandbox run of the same project finds those files through the same volume

#### Scenario: Privileged mode is opt-in
- **WHEN** the manifest sets `privileged = true`
- **THEN** the sandbox container starts in privileged mode and can create nested namespaces

#### Scenario: Undeclared grants are absent
- **WHEN** the manifest declares no ports, env vars, volumes, extra mounts, or privileged mode
- **THEN** the container publishes no ports, mounts no volumes, runs without privileged mode, and carries no extra grants
