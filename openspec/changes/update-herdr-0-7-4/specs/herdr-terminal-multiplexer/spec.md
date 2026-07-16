## MODIFIED Requirements

### Requirement: Herdr is pinned via a flake input

The system SHALL declare herdr as a flake input at `inputs.herdr.url = "github:ogulcancelik/herdr/v0.7.4"` and SHALL NOT override its nixpkgs input via `follows`.

#### Scenario: Herdr flake input is declared

- **WHEN** the flake is evaluated (`nix flake check` or `nix flake show`)
- **THEN** the `herdr` input resolves to the `github:ogulcancelik/herdr` repository at tag `v0.7.4`
- **THEN** the herdr package builds from the flake's own `nix/package.nix` using its own nixpkgs
