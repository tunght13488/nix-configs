## Purpose

Manage Ghostty terminal emulator installation and configuration via home-manager.

## Requirements

### Requirement: Ghostty terminal emulator is installed
The system SHALL install Ghostty via the home-manager `programs.ghostty` module, making it available alongside the existing Alacritty installation.

#### Scenario: Ghostty binary is available
- **WHEN** the home-manager configuration is applied
- **THEN** the `ghostty` binary is on PATH and executable

#### Scenario: Alacritty is unaffected
- **WHEN** Ghostty is enabled
- **THEN** the `programs.alacritty` configuration remains intact and functional

### Requirement: Ghostty uses matching font and cursor settings
Ghostty SHALL be configured with the same font family, font size, and cursor style as the existing Alacritty configuration.

#### Scenario: Font configuration
- **WHEN** Ghostty is launched
- **THEN** the default font is Monaspace Krypton NF at size 10

#### Scenario: Cursor appearance
- **WHEN** Ghostty is launched
- **THEN** the cursor is a bar shape without blinking

### Requirement: Zsh shell integration is enabled
Ghostty SHALL provide shell integration in Zsh sessions, enabling features like working directory reporting and prompt marking.

#### Scenario: Shell integration activates in Zsh
- **WHEN** a Zsh session is started inside Ghostty
- **THEN** the Ghostty shell integration script is sourced automatically
