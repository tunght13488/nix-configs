# Proposal

## Why

This repository already installs Orca and exposes its Linux CLI, but it does not run Orca's headless server as a persistent service. A supervised service would make the Orca runtime available after reboot and recover it after server failures without requiring a desktop session or manual launch.

## What Changes

- Run Orca's headless `serve` runtime as a declarative systemd user service, using Orca's documented supervisor mode.
- Keep the user service manager alive at boot and across logout so the server does not depend on an interactive login.
- Use the existing Tailscale setup for remote access; do not add public port forwarding. Initial client pairing remains a one-time Orca setup step.
- Preserve the installed desktop app and existing `orca-ide` CLI behavior.

## Capabilities

### New Capabilities

<!-- No new capability; this extends the existing Orca installation capability. -->

### Modified Capabilities

- `orca-app`: Add a headless server that starts at boot and recovers from server-process failures.

## Impact

- Home Manager Orca configuration and the NixOS user/service configuration for `tung`.
- Existing Orca package and CLI; no new flake inputs or external service dependencies.
- The service uses Orca's server port and existing Tailscale access. The current firewall configuration must be checked so the server is not exposed beyond the intended trusted network.
