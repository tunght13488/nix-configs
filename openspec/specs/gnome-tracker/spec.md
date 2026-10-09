## Purpose

Defines the system-level behavior for GNOME Tracker indexing services, allowing the GNOME desktop to remain enabled without these background services.

## Requirements

### Requirement: GNOME Tracker services are disabled
The NixOS system configuration SHALL disable both GNOME Tracker and Tracker Miners as managed services. This SHALL NOT disable GNOME or GDM.

#### Scenario: GNOME desktop remains available without Tracker services
- **WHEN** the configured NixOS generation is activated with GNOME enabled
- **THEN** GNOME and GDM remain available, while Tracker and Tracker Miners are disabled and are not started by the system.
