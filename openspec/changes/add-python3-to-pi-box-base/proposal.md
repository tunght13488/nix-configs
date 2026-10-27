# Proposal

## Why

The shared pi-box base image does not explicitly provide a Python 3 interpreter, so projects that only need to run Python scripts must add their own setup. Adding the distro-provided interpreter to the common image makes it available across sandboxes without introducing a Python package-management workflow.

## What Changes

- Add the distro's `python3` interpreter to the shared pi-box base image so it is available in the base and derived project images.
- Keep this interpreter-only: do not add pip, venv, uv, a Python template, or a separately pinned Python version.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `pi-box-sandbox`: require Python 3 in the shared base image.

## Impact

- `home-manager/pi-sandbox.Dockerfile`: install Python 3 in the stable shared OS-tooling layer.
- `AGENTS.md` and the five shipped template Dockerfiles: keep their descriptions of the common base toolchain accurate.
- `openspec/specs/pi-box-sandbox/spec.md`: add the shared Python 3 runtime behavior and its availability scenario.
- Verify the rebuilt base and a derived project image expose `python3`. No changes to the pi-box wrapper, sandbox grants, or host `python-toolchain` are in scope.
