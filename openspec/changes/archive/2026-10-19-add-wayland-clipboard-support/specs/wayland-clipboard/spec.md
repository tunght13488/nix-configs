# Spec Delta

## Purpose

Provide the Wayland clipboard command-line tools in the managed user environment so terminal tools such as herdr can copy text to and paste from the Wayland clipboard.

## ADDED Requirements

### Requirement: Wayland clipboard tools are available in the managed user environment

The managed user environment SHALL install the `wl-clipboard` package and make the `wl-copy` and `wl-paste` commands available on PATH after the Home Manager configuration is applied.

#### Scenario: Clipboard commands are available

- **WHEN** the Home Manager configuration is applied and the user opens a new shell
- **THEN** invoking `wl-copy` and `wl-paste` resolves to executable commands in the user's environment

### Requirement: Clipboard tools work in both GNOME and Hyprland sessions

The clipboard tools SHALL remain usable in both the default GNOME session and the optional Hyprland session, with no session-specific gating, so terminal tools such as herdr can copy text regardless of the active desktop session.

#### Scenario: Copy and paste in the GNOME session

- **WHEN** the user is in a GNOME session with the managed environment applied and copies text via `wl-copy`
- **THEN** `wl-paste` returns the copied text and other Wayland applications can read it from the clipboard

#### Scenario: Copy and paste in a Hyprland session

- **WHEN** the user is in a regular or UWSM-managed Hyprland session with the managed environment applied and copies text via `wl-copy`
- **THEN** `wl-paste` returns the copied text and other Wayland applications can read it from the clipboard

### Requirement: No clipboard manager is introduced

The change SHALL add only the clipboard command-line tools and SHALL NOT introduce a clipboard manager daemon, background service, or keybinding configuration.

#### Scenario: Only CLI tools are present

- **WHEN** the Home Manager configuration with `wl-clipboard` is applied
- **THEN** no new clipboard manager service is started and no clipboard-related keybindings are added
