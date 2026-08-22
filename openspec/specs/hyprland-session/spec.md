## Purpose

Provides a reversible way to test the Hyprland Wayland compositor on the VMware host without replacing the existing GNOME desktop or GDM login path.

## Requirements

### Requirement: Hyprland is available as an optional GDM session
The system SHALL expose Hyprland as a selectable Wayland session through the existing GDM display manager, including the UWSM-managed Hyprland session when UWSM integration is enabled.

#### Scenario: Hyprland sessions are registered
- **WHEN** a system generation containing the Hyprland session configuration is built
- **THEN** GDM remains the active display-manager implementation and its available session data includes `hyprland` and `hyprland-uwsm`

#### Scenario: User selects Hyprland from GDM
- **WHEN** the user selects either Hyprland session in GDM and authenticates
- **THEN** the user session starts the Hyprland Wayland compositor rather than GNOME

### Requirement: GNOME remains the default and usable fallback
The system SHALL keep GNOME and GDM enabled, SHALL retain GNOME as the default graphical session, and SHALL leave GNOME selectable after Hyprland is added.

#### Scenario: Normal login preserves GNOME
- **WHEN** the user logs in without selecting another session
- **THEN** GDM starts the GNOME session as it did before this change

#### Scenario: User rolls back from a Hyprland test
- **WHEN** the user returns to the GDM session chooser after testing Hyprland
- **THEN** the user can select GNOME and receive the existing GNOME desktop without reverting the system generation

### Requirement: Existing VMware graphics and desktop support remain available
The Hyprland test session SHALL coexist with the existing VMware guest graphics configuration, X server support, and GNOME-specific system configuration; adding Hyprland MUST NOT require removing or replacing those components.

#### Scenario: Existing graphics configuration is preserved
- **WHEN** the Hyprland-enabled system generation is evaluated
- **THEN** the existing VMware video-driver and guest-tool configuration remains enabled and the existing GNOME/GDM configuration remains present

#### Scenario: Wayland application integration is available
- **WHEN** the user starts the Hyprland session
- **THEN** the session is a Wayland session with the Hyprland-provided XWayland and desktop-portal integration available for applications that need them