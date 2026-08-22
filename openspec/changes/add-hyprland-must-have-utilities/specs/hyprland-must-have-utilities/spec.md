## Purpose

Provides the optional Hyprland session with the notification, authentication, font, and Qt Wayland support needed for a usable desktop while keeping the existing GNOME session isolated and available as the default fallback.

## ADDED Requirements

### Requirement: Hyprland provides desktop notifications

The Hyprland session SHALL provide `fnott` as its single desktop notification daemon, with the standard desktop notification interface available to applications during both the regular and UWSM-managed Hyprland sessions.

#### Scenario: Regular Hyprland notifications

- **WHEN** the user selects the regular Hyprland session from GDM and an application emits a desktop notification
- **THEN** the notification is displayed by `fnott` without requiring the user to start the daemon manually

#### Scenario: UWSM Hyprland notifications

- **WHEN** the user selects the UWSM-managed Hyprland session from GDM and an application emits a desktop notification
- **THEN** the notification is displayed by `fnott` through the session's user service environment

### Requirement: Hyprland provides graphical PolicyKit authentication

The Hyprland session SHALL provide a graphical PolicyKit authentication agent that is available when a graphical application requests elevated privileges.

#### Scenario: Authentication request in Hyprland

- **WHEN** a graphical application requests PolicyKit authorization during a Hyprland session
- **THEN** the user receives a graphical authentication prompt and can authorize the request with a valid password

### Requirement: Hyprland provides recommended font and Qt Wayland support

The managed user environment SHALL provide Noto fonts and Qt 5 and Qt 6 Wayland platform support so applications using either Qt major version can render and use native Wayland integration in Hyprland.

#### Scenario: Font fallback in Hyprland

- **WHEN** a Hyprland application requests a common sans-serif or fallback glyph covered by the Noto family
- **THEN** fontconfig can discover an installed Noto font instead of falling back to missing-glyph squares

#### Scenario: Qt 5 and Qt 6 Wayland applications

- **WHEN** a Qt 5 or Qt 6 graphical application is launched in Hyprland
- **THEN** its corresponding Wayland platform support is available without requiring an imperative package installation

### Requirement: GNOME remains isolated from Hyprland utilities

The notification and PolicyKit services introduced by this capability SHALL only run for a Hyprland session and SHALL NOT replace or compete with GNOME's existing notification and authentication services.

#### Scenario: GNOME remains the default

- **WHEN** the user logs in through GDM without selecting another session
- **THEN** GDM starts GNOME as the default session and the existing GNOME notification and authentication behavior remains in control

#### Scenario: Returning to GNOME after Hyprland

- **WHEN** the user logs out of Hyprland and later selects GNOME from GDM
- **THEN** `fnott` and `hyprpolkitagent` are not running as the active GNOME session services and GNOME remains usable without reverting the system generation
