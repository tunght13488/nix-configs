# Spec Delta

## ADDED Requirements

### Requirement: Python 3 interpreter in the shared base image
The shared `pi-sandbox` image SHALL provide a Python 3 interpreter available as `python3` in both the base image and project images derived from it.

#### Scenario: Python runs in the base image
- **WHEN** `python3 --version` runs in a sandbox using the base image
- **THEN** it succeeds and reports a Python 3 version

#### Scenario: Python is inherited by project images
- **WHEN** `python3 --version` runs in a sandbox using a project image derived from `pi-sandbox`
- **THEN** it succeeds and reports a Python 3 version without project-specific Python installation
