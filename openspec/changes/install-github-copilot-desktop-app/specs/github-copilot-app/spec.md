# Spec Delta

## Purpose

Defines how the official GitHub Copilot desktop app is packaged and made available in the configured Linux desktop environment, independently of the existing Copilot CLI.

## ADDED Requirements

### Requirement: The desktop app uses a pinned official Linux release

The configuration SHALL provide the official GitHub Copilot desktop app for the configured x86_64 Linux system from an upstream release with a fixed version and verified content hash.

#### Scenario: The package is reproducibly sourced

- **WHEN** the desktop app package is evaluated
- **THEN** its source is the official GitHub App release for the Linux x86_64 AppImage
- **AND** the artifact is checked against a fixed SHA-256 hash

### Requirement: The app is installed for the user

The GitHub Copilot desktop app SHALL be included in the user's declarative Home Manager package set.

#### Scenario: The Home Manager build includes the app

- **WHEN** the Home Manager configuration is built
- **THEN** the packaged desktop app is available to the user without a separate manual installation

### Requirement: The app is launchable from the desktop grid

The installed app SHALL provide a desktop entry and icon that launch the packaged GitHub Copilot desktop app from the GNOME application grid.

#### Scenario: Launching from the application grid

- **WHEN** the user launches GitHub Copilot from the GNOME application grid
- **THEN** the packaged desktop app starts

### Requirement: The desktop app does not replace the Copilot CLI

Installing the desktop app SHALL preserve the existing GitHub Copilot CLI and Neovim Copilot integration.

#### Scenario: The CLI remains available with the app installed

- **WHEN** the Home Manager configuration includes the desktop app
- **THEN** `github-copilot-cli` remains installed and the existing Neovim Copilot configuration remains unchanged
