# Proposal

## Why

The shared pi-box sandbox currently pins Pi coding-agent 1.5.1. Updating it to the requested 1.5.2 release keeps the sandbox runtime and its documented version requirement aligned.

## What Changes

- Pin the Pi coding agent installed in the shared pi-box image to 1.5.2.
- Update the sandbox version requirement and scenarios to 1.5.2; project images that do not replace Pi continue to inherit the shared version.
- Leave the host Pi installation, wrapper, image layering, templates, and sandbox grants unchanged.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `pi-box-sandbox`: update the required Pi coding-agent release from 1.5.1 to 1.5.2.

## Impact

- `home-manager/pi-sandbox.nix` version pin; the existing `home-manager/pi-box.sh` build-argument path installs it through `home-manager/pi-sandbox.Dockerfile`.
- `openspec/specs/pi-box-sandbox/spec.md` version requirement and verification scenarios.
- The base image uses Node 24, which satisfies Pi 1.5.2's Node.js `>=22.19.0` requirement.
