# JetBrains Toolbox

## Purpose

Document the sourcing, version tracking, and integration contract for the JetBrains Toolbox launcher within the NixOS + home-manager configuration. The Toolbox launcher is provided via `pkgs.unstable` (the `nixpkgs-unstable` flake input), separate from the JetBrains IDEs it manages (which live outside nix in `~/.local/share/JetBrains/Toolbox/apps/` and are self-updating).

## Requirements

### Requirement: JetBrains Toolbox is sourced from the nixpkgs-unstable input

The home-manager configuration SHALL provide `jetbrains-toolbox` from the `pkgs.unstable` overlay (the `nixpkgs-unstable` flake input) using the flat top-level attribute `unstable.jetbrains-toolbox`, and SHALL NOT source it from the `nixos-25.11` (`nixpkgs`) input. This follows the existing `unstable.*` convention already used for `unstable.postman`, `unstable.zed-editor`, `unstable.uv`, and `unstable.openspec`.

#### Scenario: Package entry resolves to the unstable input

- **WHEN** the home-manager configuration is evaluated (`make home-build`)
- **THEN** the `jetbrains-toolbox` entry in `home-manager/home.nix` `home.packages` is `unstable.jetbrains-toolbox`
- **THEN** evaluation succeeds without referencing the `nixos-25.11` `jetbrains-toolbox` attribute for this package

#### Scenario: Resolved version tracks a current upstream build

- **WHEN** the `nixpkgs-unstable` flake input has been bumped to a revision containing nixpkgs PR #542679 (`jetbrains-toolbox: 3.6.1.85592 -> 3.6.2.85969`) or later
- **THEN** the built `jetbrains-toolbox` store path version is `3.6.2.85969` or newer
- **THEN** `jetbrains-toolbox --version` prints a version `>= 3.6.2`

### Requirement: The nixpkgs-unstable bump is targeted

The `flake.lock` update accompanying this change SHALL advance only the `nixpkgs-unstable` node (via `nix flake update nixpkgs-unstable` or equivalent). The `nixos-25.11` nixpkgs, `home-manager`, `nixvim`, `agenix`, `nix-index-database`, and `phps` input revisions SHALL remain unchanged.

#### Scenario: Only the unstable input moves

- **WHEN** the `flake.lock` diff is reviewed after the change
- **THEN** only the `nixpkgs-unstable` node's `rev`/`narHash`/`lastModified` differ from the prior commit
- **THEN** the `nixpkgs`, `home-manager`, `nixvim`, `agenix`, `nix-index-database`, and `phps` nodes are byte-identical to the prior commit

### Requirement: JetBrains IDEs remain Toolbox-managed and out of scope

The system SHALL continue to let JetBrains IDEs be installed and updated by Toolbox under `~/.local/share/JetBrains/Toolbox/apps/`. This change SHALL NOT alter IDE installation paths, IDE update behavior, or any IDE configuration under `~/.config/JetBrains` or `~/.cache/JetBrains`.

#### Scenario: IDE state is untouched by the change

- **WHEN** the home-manager build is switched to the new Toolbox version
- **THEN** the contents of `~/.local/share/JetBrains/Toolbox/apps/` are unchanged by nix
- **THEN** previously installed IDEs (`intellij-idea`, `phpstorm`, `webstorm`, `air`) launch from their existing `~/.local/share` paths without reinstallation
