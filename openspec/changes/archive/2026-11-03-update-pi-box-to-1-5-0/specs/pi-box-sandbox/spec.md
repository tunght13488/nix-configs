# Spec Delta

## ADDED Requirements

### Requirement: Sandboxed Pi uses release 1.5.0
The shared `pi-sandbox` base image SHALL install Pi coding-agent release `1.5.0`. Project images that do not replace the Pi executable SHALL inherit that release from the shared base image.

#### Scenario: Base image provides Pi 1.5.0
- **WHEN** `pi-box` rebuilds the shared base image after the Home Manager version pin is updated
- **THEN** the `pi --version` command in the image reports `1.5.0`

#### Scenario: Project image inherits Pi 1.5.0
- **WHEN** a project image is built from the updated shared base image without replacing Pi
- **THEN** the project's `pi --version` command reports `1.5.0`
