# Herdr Core Specification

## Purpose

Provides the herdr-core (`hc`) binary on the user's PATH via home-manager, built from the pinned `herdrdev/herdr-core` source, so agents and scripts can run durable terminals from the shell alongside the herdr TUI.

## Requirements

### Requirement: Herdr-core is available as a home-manager package

The system SHALL make the `hc` binary available in the user's PATH via home-manager's `home.packages`, installed from the pinned `herdr-core` package alongside the existing herdr TUI.

#### Scenario: hc binary is on PATH after home-manager switch

- **WHEN** the user runs `home-manager switch` with the herdr-core package included
- **THEN** the `hc` command is available in the shell PATH
- **THEN** `hc --help` exits successfully and lists the core's commands

### Requirement: Herdr-core is pinned to an upstream release

The system SHALL pin the herdr-core source in the package derivation to the `github:herdrdev/herdr-core` revision at tag `v0.1.21`, fetched with its Ghostty vendor submodule.

#### Scenario: Herdr-core source is pinned

- **WHEN** the package derivation is evaluated
- **THEN** the fetched source corresponds to the `github:herdrdev/herdr-core` repository at tag `v0.1.21`
- **THEN** the `vendor/ghostty` submodule contents are present in the build source

### Requirement: Herdr-core builds hermetically from the pinned source

The system SHALL provide a Nix derivation that builds the `hc` binary from the pinned source with `cargo build --locked`, using the vendored Ghostty submodule and Zig 0.16, without network access in the sandbox.

#### Scenario: herdr-core package builds

- **WHEN** the user runs `nix build .#herdr-core`
- **THEN** the build succeeds and produces `result/bin/hc`
- **THEN** the build fetches no dependencies from the network during the build phase

### Requirement: Herdr-core coexists with the herdr TUI

The system SHALL install herdr-core alongside the existing herdr package without removing or altering the herdr TUI, its config bootstrapping, or its agent skill linking.

#### Scenario: Both binaries remain available after the change

- **WHEN** home-manager activates with herdr-core added
- **THEN** both `hc` and `herdr` are available in the user's PATH
- **THEN** the herdr config bootstrap and agent skill symlinks in `home-manager/herdr.nix` continue to apply unchanged
