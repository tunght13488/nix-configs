## MODIFIED Requirements

### Requirement: Herdr is pinned via a flake input

The system SHALL declare herdr as a flake input at `inputs.herdr.url = "github:herdrdev/herdr/v0.8.2"` and SHALL NOT override its nixpkgs input via `follows`.

#### Scenario: Herdr flake input is declared

- **WHEN** the flake is evaluated (`nix flake check` or `nix flake show`)
- **THEN** the `herdr` input resolves to the `github:herdrdev/herdr` repository at tag `v0.8.2`
- **THEN** the herdr package builds from the flake's own `nix/package.nix` using its own nixpkgs
