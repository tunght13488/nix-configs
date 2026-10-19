# Spec Delta

## Purpose

Defines how the Obsidian desktop app is sourced, versioned, installed, and integrated into the desktop environment for this NixOS + home-manager configuration.

## ADDED Requirements

### Requirement: Obsidian is sourced from the official upstream AppImage

The configuration SHALL provide Obsidian through a custom package that wraps the official Obsidian AppImage from the `obsidianmd/obsidian-releases` GitHub releases, using `appimageTools.wrapType2` from the pinned `nixos-26.05` nixpkgs input. The change SHALL NOT use the nixpkgs `obsidian` package (which builds from a source tarball and lags upstream) and SHALL NOT source Obsidian from `pkgs.unstable`.

#### Scenario: Package source is the official AppImage

- **WHEN** the `obsidian` package is evaluated
- **THEN** its `src` is a fixed-output fetch of `Obsidian-<version>.AppImage` from the official Obsidian GitHub releases
- **AND** no nixpkgs `obsidian` attribute is referenced anywhere in the configuration

### Requirement: The package is pinned to a specific upstream version

The package SHALL pin an explicit upstream Obsidian version with a matching fixed-output hash. Updating Obsidian SHALL be a repin of the version and hash in the package definition only, requiring no flake input or `flake.lock` changes.

#### Scenario: Updating Obsidian

- **WHEN** a new upstream Obsidian release is available
- **THEN** updating this configuration changes only the version and hash in the package definition
- **AND** `flake.lock` remains byte-identical

### Requirement: Obsidian is installed for the user via home-manager

The package SHALL be exposed through the `additions` overlay (`pkgs.obsidian`) and the flake packages output (`nix build .#obsidian`), and SHALL be installed for user `tung` via `home.packages` in `home-manager/home.nix`.

#### Scenario: Obsidian is available after a home-manager switch

- **WHEN** the home-manager configuration is activated with this change
- **THEN** an `obsidian` executable is on the user's `PATH`
- **AND** launching it starts the Obsidian application

### Requirement: Obsidian appears in the desktop application grid

The package SHALL ship a desktop entry and an icon so Obsidian is listed in the GNOME application grid. The desktop entry's `Exec` field SHALL reference the wrapped `obsidian` binary provided by the package.

#### Scenario: Launching Obsidian from the desktop environment

- **WHEN** the user opens Obsidian from the GNOME application grid
- **THEN** the Obsidian application starts with the same behavior as launching `obsidian` from a shell

### Requirement: User data and unrelated AppImage tooling are untouched

The change SHALL NOT alter Obsidian user data locations (vault directories, `~/.config/obsidian`) and SHALL NOT modify the NixOS `programs.appimage` module settings, which remain as-is.

#### Scenario: Existing AppImage infrastructure stays unchanged

- **WHEN** the NixOS configuration is evaluated with this change
- **THEN** the `programs.appimage` settings are identical to their state before the change
- **AND** no files under user vault or `~/.config/obsidian` paths are created or modified by the package
