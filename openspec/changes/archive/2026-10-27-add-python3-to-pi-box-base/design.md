# Design

## Context

See `proposal.md` for the motivation. The base Dockerfile starts from `node:24-slim`, installs common OS tools in a stable apt layer, then adds the container-safe Git configuration and pinned Pi agent. `pi-box` builds this base on each run with Docker layer caching, and all project images extend `pi-sandbox`. The base Dockerfile does not explicitly install Python 3.

## Goals / Non-Goals

**Goals:**

- Make the distribution-provided `python3` interpreter available in the shared base and every derived project image.
- Keep Python in the stable common-tools layer and document it as part of the base image.

**Non-Goals:**

- Provide pip, venv, uv, a Python project template, or a separately pinned Python minor version.
- Change the host Python/uv setup, pi-box wrapper, or sandbox grants.

## Decisions

- Install the Debian `python3` package in the existing apt install step in `home-manager/pi-sandbox.Dockerfile`. This follows the base image's package source and layer structure, and exposes the requested `python3` command without introducing another installer. Installing Python separately in each project image would duplicate setup and fail to make it available in the base sandbox; using the host's Nix Python would not make it available inside the container.
- Keep Python in the shared base rather than adding a project template. This is the requested behavior and means existing and future `FROM pi-sandbox` images inherit the interpreter.
- Verify `python3 --version` in the base image and in a derived project image. Update the common-toolchain inventory in `AGENTS.md` and the shipped template Dockerfile comments so they match the base contents.

## Risks / Trade-offs

- [Python minor version follows the Debian package selected by the base image] -> Accept this for the interpreter-only requirement; pin the distribution or package version only if a future requirement needs a fixed minor version.
- [The shared apt-layer change invalidates downstream base-image build layers, and derived project images see a changed parent] -> Rebuild through the existing `pi-box` flow and verify both a base and derived image; Docker caching retains the rebuilt layers for subsequent runs.
- [The interpreter does not provide a Python dependency-installation workflow] -> Keep that out of scope as decided; projects needing dependencies can define their own toolchain separately.

## Migration Plan

After the Home Manager configuration is applied, the next `pi-box` run builds the updated base image. Project images are rebuilt from the new base as they are next used. To roll back, remove the package from the base Dockerfile, redeploy it, and let `pi-box` rebuild the base; project-specific Dockerfiles need no migration.
