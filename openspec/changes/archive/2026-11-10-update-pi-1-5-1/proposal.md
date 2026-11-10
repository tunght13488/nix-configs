# Proposal

## Why

The pi-box sandbox currently pins Pi coding-agent 1.5.0. Updating the pin to 1.5.1 keeps the sandbox on the requested release and updates the version guarantee documented for the sandbox.

## What Changes

- Update the Pi release installed in the shared pi-box base image from 1.5.0 to 1.5.1.
- Update the sandbox specification to require Pi 1.5.1, including the inherited version in project images.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `pi-box-sandbox`: change the required sandbox Pi release from 1.5.0 to 1.5.1.

## Impact

- `home-manager/pi-sandbox.nix` version pin, consumed by `home-manager/pi-box.sh` and `home-manager/pi-sandbox.Dockerfile` when the base image is built.
- `openspec/specs/pi-box-sandbox/spec.md` release requirement and scenarios.
