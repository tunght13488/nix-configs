# Spec Delta

## ADDED Requirements

### Requirement: nix-configs template provides the repository toolchain
The `nix-configs` template SHALL provide the tools needed to run this repository's non-human Makefile targets inside pi-box, while retaining the existing OpenSpec CLI.

#### Scenario: Project commands are available
- **WHEN** a project is scaffolded with `pi-box init nix-configs` and launched
- **THEN** `make`, `find`, `xargs`, `nproc`, a Nix CLI with `nix-command` and `flakes`, `nh`, `nixos-rebuild`, `nixpkgs-fmt`, and `openspec` are available in the sandbox

#### Scenario: Allowed targets use the sandbox workspace
- **WHEN** `make format`, `make home-build`, `make os-build`, or `make update` runs from the project root
- **THEN** the target runs inside pi-box and workspace changes are visible on the host

### Requirement: nix-configs template persists a private Nix store
The `nix-configs` template SHALL persist its Nix store across pi-box runs in a named Docker volume and SHALL NOT mount or use the host Nix store or daemon.

#### Scenario: Store survives container removal
- **WHEN** a later pi-box run uses the same project volume
- **THEN** Nix store paths from an earlier run remain available

#### Scenario: Host Nix is not exposed
- **WHEN** the sandbox runs from the `nix-configs` template
- **THEN** the host Nix store and daemon socket are not mounted in the container

### Requirement: nix-configs template keeps Nix build sandboxing enabled
The `nix-configs` template SHALL keep Nix's build sandbox enabled with sandbox fallback disabled, and SHALL declare the sandbox privileges that Nix requires to create its build namespaces, so builds run hermetic instead of silently degrading.

#### Scenario: Sandboxed build succeeds
- **WHEN** a derivation is built inside the sandbox from this template
- **THEN** the build completes with Nix sandboxing enabled

#### Scenario: Missing privileges fail instead of degrading
- **WHEN** the sandbox runs without the required privileges
- **THEN** Nix reports that sandboxing is unsupported rather than building unsandboxed

### Requirement: nix-configs pi-box instructions distinguish human-only targets
The project instructions SHALL mark `make os`, `make os-boot`, `make home`, `make clean`, and `make os-test` as human-only, and permit Pi to invoke the other Makefile targets. This policy SHALL be instruction-only, without Makefile target gating.

#### Scenario: Pi follows the target policy
- **WHEN** Pi reads the project instructions before using the Makefile
- **THEN** the five human-only targets are identified and the remaining targets are available for Pi to invoke
