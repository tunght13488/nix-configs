# Proposal

## Why

`pi-box` currently pins the Pi coding agent in its shared sandbox image to `1.4.0`. Upgrade that runtime to the requested `1.5.0` release while keeping the install deterministic and using the existing version-pin/build-argument path.

## What Changes

- Pin the shared sandbox image's Pi coding agent to `1.5.0`.
- Keep the wrapper, image layering, project templates, and sandbox grants unchanged; the next `pi-box` run after applying Home Manager rebuilds the Pi image layer with the new pin.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `pi-box-sandbox`: Specify the Pi coding-agent release installed in the shared sandbox image.

## Impact

- `home-manager/pi-sandbox.nix` contains the version pin; `home-manager/pi-box.sh` passes it as the Docker build argument, and `home-manager/pi-sandbox.Dockerfile` installs that package version.
- The image uses Node 24, which satisfies Pi 1.5.0's Node.js `>=22.19.0` requirement.
- Pi 1.5.0 changes custom tool argument validation. User-managed extensions that rely on TypeBox-only features outside JSON Schema may need compatibility review.
