# Design

## Context

`home-manager/pi-sandbox.nix` pins `piVersion` to `1.4.0` and substitutes it into the `pi-box` wrapper. The wrapper passes that value as `PI_VERSION` to `home-manager/pi-sandbox.Dockerfile`, where npm installs the pinned agent in the final image layer. The base image uses Node 24; Pi 1.5.0 requires Node.js `>=22.19.0`, so the existing runtime satisfies the release requirement. See the [Pi 1.5.0 release notes](https://github.com/earendil-works/pi/releases/tag/v1.5.0).

## Goals / Non-Goals

**Goals:**
- Have the shared sandbox image run the explicitly requested Pi 1.5.0 release after Home Manager is applied and the image is rebuilt.
- Preserve deterministic installs and Docker cache reuse for the stable base-image layers.

**Non-Goals:**
- Change the host Pi installation, wrapper CLI, base Node image, templates, or sandbox grants.
- Automatically migrate user-managed extensions or their custom tool schemas.

## Decisions

- Change only the `piVersion` pin in `home-manager/pi-sandbox.nix`. The existing substitution and build-argument path already installs that exact version; changing the Dockerfile or using a floating `latest` tag would duplicate or weaken the pin.
- Keep Node 24. It meets the release's minimum Node version, so a base-runtime change is unnecessary.
- Keep the Pi installation as the final image layer. Changing the build argument should rebuild the Pi install layer while retaining the stable OS-tooling and Git-configuration layers.
- Treat extension compatibility as a rollout check, not a repository migration. Pi 1.5.0 changes tool-argument validation: TypeBox-only constructs outside JSON Schema no longer apply. The extensions are user-managed in the shared Pi state and are not configured in this repository.

## Risks / Trade-offs

- [A user-managed extension relies on TypeBox-only tool-schema behavior] → Smoke-test configured custom tools after upgrade; handle any extension migration separately rather than changing out-of-scope global state.
- [Pi 1.5.0 writes state that Pi 1.4.0 cannot read] → Before rolling back after the new agent has run, verify compatibility of the shared `~/.pi/agent` state; the sandbox mounts that state read-write.

## Migration Plan

1. Run `make home-build` to validate the Home Manager configuration.
2. After Home Manager is applied, run `pi-box --version`. This rebuilds the shared image if needed; verify it reports `1.5.0`. If using a project image, verify it still builds from the updated base image.
3. Exercise any configured extension tools that use custom schemas.
4. To roll back, restore the pin to `1.4.0`, apply Home Manager, and run `pi-box` to rebuild the base image. Check shared-state compatibility before resuming sessions with the older agent.
