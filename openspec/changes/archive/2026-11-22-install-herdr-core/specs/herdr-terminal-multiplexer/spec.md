# Spec Delta

## MODIFIED Requirements

### Requirement: Herdr is pinned via a flake input

The system SHALL declare herdr as a flake input from `github:herdrdev/herdr` pinned to the latest stable release tag, and SHALL NOT override its nixpkgs input via `follows`.

#### Scenario: Herdr flake input is declared

- **WHEN** the flake is evaluated (`nix flake check` or `nix flake show`)
- **THEN** the `herdr` input resolves to the `github:herdrdev/herdr` repository at the latest stable release tag (v0.9.5 at planning time; a newer tag when one exists)
- **THEN** the herdr package builds from the flake's own `nix/package.nix` using its own nixpkgs
