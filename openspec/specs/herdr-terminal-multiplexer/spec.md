# Herdr Terminal Multiplexer

## Purpose

Provide the `herdr` terminal multiplexer binary on the user's PATH, installed from a pinned flake input alongside the existing tmux setup.

## Requirements

### Requirement: Herdr is available as a home-manager package

The system SHALL make the `herdr` binary available in the user's PATH via home-manager's `home.packages`, installed from a pinned flake input.

#### Scenario: Herdr binary is on PATH after home-manager switch

- **WHEN** the user runs `home-manager switch` with the herdr package included
- **THEN** the `herdr` command is available in the shell PATH
- **THEN** running `herdr` starts the Herdr terminal multiplexer

### Requirement: Herdr is pinned via a flake input

The system SHALL declare herdr as a flake input at `inputs.herdr.url = "github:ogulcancelik/herdr/v0.7.1"` and SHALL NOT override its nixpkgs input via `follows`.

#### Scenario: Herdr flake input is declared

- **WHEN** the flake is evaluated (`nix flake check` or `nix flake show`)
- **THEN** the `herdr` input resolves to the `github:ogulcancelik/herdr` repository at tag `v0.7.1`
- **THEN** the herdr package builds from the flake's own `nix/package.nix` using its own nixpkgs

### Requirement: Herdr overlay is applied to home-manager

The system SHALL apply `herdr.overlays.default` in the home-manager nixpkgs configuration so that `pkgs.herdr` resolves to the flake-provided package.

#### Scenario: pkgs.herdr resolves in home-manager context

- **WHEN** home-manager evaluates `pkgs.herdr`
- **THEN** it resolves to the herdr derivation from the pinned flake input

### Requirement: Existing tmux configuration is unchanged

The system SHALL NOT modify or remove the existing tmux configuration. Herdr SHALL coexist alongside tmux as an independently available binary.

#### Scenario: tmux remains installed and configured after adding herdr

- **WHEN** herdr is added to `home.packages`
- **THEN** the existing tmux package and its home-manager configuration (`tmux.nix`) remain intact
- **THEN** `tmux` continues to function as before
