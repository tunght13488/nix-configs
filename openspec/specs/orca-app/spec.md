# orca-app Specification

## Purpose

Provides the Orca desktop IDE, packaged from the official upstream AppImage, in the user's declarative Home Manager environment without colliding with nixpkgs' GNOME screen-reader `orca` package.

## Requirements

### Requirement: The app uses a pinned official Linux release

The configuration SHALL provide the official Orca desktop IDE for the configured x86_64 Linux system from an upstream GitHub release with a fixed version and verified content hash.

#### Scenario: The package is reproducibly sourced

- **WHEN** the Orca package is evaluated
- **THEN** its source is the official `stablyai/orca` release AppImage for Linux x86_64
- **AND** the artifact is checked against a fixed SHA-256 hash

### Requirement: The app is installed for the user

The Orca desktop IDE SHALL be included in the user's declarative Home Manager package set.

#### Scenario: The Home Manager build includes the app

- **WHEN** the Home Manager configuration is built
- **THEN** the packaged Orca app is available to the user without a separate manual installation

### Requirement: The app is launchable from the desktop grid

The installed app SHALL provide a desktop entry and icon that launch the packaged Orca IDE from the GNOME application grid.

#### Scenario: Launching from the application grid

- **WHEN** the user launches Orca from the GNOME application grid
- **THEN** the packaged Orca IDE starts

### Requirement: The Orca CLI is available

The installation SHALL make the bundled Orca CLI, named `orca-ide` on Linux, available on the user's PATH.

#### Scenario: Running the Orca CLI

- **WHEN** the user runs `orca-ide` from a shell in their declarative environment
- **THEN** the Orca CLI responds with its usage or starts

### Requirement: The GNOME screen reader package is unaffected

Installing Orca SHALL NOT modify, shadow, or remove the nixpkgs `orca` package (the GNOME screen reader) or its configuration.

#### Scenario: The screen reader remains intact

- **WHEN** the Home Manager configuration includes the Orca IDE
- **THEN** `pkgs.orca` still resolves to the GNOME screen reader and no file path of the screen reader is overwritten

### Requirement: Orca headless server runs independently of interactive sessions
The configuration SHALL start Orca's headless server at system boot and keep it running without a graphical session or an interactive login.

#### Scenario: System boots without a user login

- **WHEN** the system finishes booting and `tung` has not logged in
- **THEN** the Orca server is running and available to paired clients

#### Scenario: User logs out

- **WHEN** `tung` logs out while the system remains running
- **THEN** the Orca server remains available

### Requirement: Orca server recovers from process failures
The service SHALL use Orca's supervisor behavior to recover from server-process failures without a rapid restart loop.

#### Scenario: Server process exits unexpectedly

- **WHEN** the Orca server process exits because of a transient failure
- **THEN** the supervisor retries starting it with increasing delays

### Requirement: Orca server access uses a trusted private network
Remote clients SHALL reach the Orca server over the existing Tailscale network, and this change SHALL NOT configure public Internet port forwarding for the server.

#### Scenario: Paired client connects over Tailscale

- **WHEN** a paired Orca client connects using the server's Tailscale address
- **THEN** it can reach the headless server

#### Scenario: No public port forwarding is added

- **WHEN** the service configuration is applied
- **THEN** no public Internet port-forwarding rule is added for the Orca server
