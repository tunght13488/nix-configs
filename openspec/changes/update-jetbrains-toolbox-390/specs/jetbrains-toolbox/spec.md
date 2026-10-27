# Spec Delta

## MODIFIED Requirements

### Requirement: JetBrains Toolbox is sourced from the nixpkgs-unstable input

The home-manager configuration SHALL provide `jetbrains-toolbox` through `pkgs.unstable` (the `nixpkgs-unstable` flake input) using the flat top-level attribute `unstable.jetbrains-toolbox`, and SHALL NOT source it from the `nixos-25.11` (`nixpkgs`) input. The extended `unstable` set SHALL provide that attribute from the repository's own `pkgs/jetbrains-toolbox.nix`, pinned to the latest upstream release and built against the unstable package set.

#### Scenario: Package entry resolves to the unstable input

- **WHEN** the home-manager configuration is evaluated (`make home-build`)
- **THEN** the `jetbrains-toolbox` entry in `home-manager/home.nix` `home.packages` is `unstable.jetbrains-toolbox`
- **THEN** evaluation succeeds without referencing the `nixos-25.11` `jetbrains-toolbox` attribute for this package

#### Scenario: Resolved version tracks a current upstream build

- **WHEN** the `unstable.jetbrains-toolbox` derivation is evaluated
- **THEN** its version is `3.9.0.88839`
- **THEN** `jetbrains-toolbox --version` prints `3.9.0.88839`

#### Scenario: Source download uses a working JetBrains host

- **WHEN** the derivation's source is fetched during a build
- **THEN** it is downloaded from `https://download.jetbrains.com/toolbox/`, not from `download-cdn.jetbrains.com`
- **THEN** the build succeeds on a store that has no cached copy of the package

### Requirement: The nixpkgs-unstable bump is targeted

The version pin SHALL be delivered entirely by the `unstable-packages` overlay and the repository's `pkgs/jetbrains-toolbox.nix`. `flake.lock` SHALL remain unchanged by this change, and the `nixpkgs-unstable`, `nixpkgs`, `home-manager`, `nixvim`, `agenix`, `nix-index-database`, and `phps` input revisions SHALL stay byte-identical to the prior commit. Advancing `nixpkgs-unstable` is not part of the pin, so no input node moves.

#### Scenario: Only the unstable input moves

- **WHEN** the `flake.lock` diff is reviewed after the change
- **THEN** no input node differs from the prior commit, because the pin lands in the overlay instead of the lockfile

#### Scenario: Other unstable packages are unaffected

- **WHEN** the change is applied
- **THEN** `unstable.postman`, `unstable.zed-editor`, `unstable.uv`, and `unstable.openspec` resolve to the same derivations as before the change
