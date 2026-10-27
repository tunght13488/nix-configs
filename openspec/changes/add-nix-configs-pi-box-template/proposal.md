# Proposal

## Why

The current project-local `Dockerfile.pi` adds OpenSpec to the shared pi-box image, but does not provide Nix or the tools used by this repository's Makefile. Pi can edit the Nix configuration in the sandbox, but cannot run its non-human Makefile targets there. A versioned project template makes that workflow reproducible across worktrees.

## What Changes

- Add a `nix-configs` pi-box template with a flake-capable Nix toolchain for `make format`, `make home-build`, `make os-build`, and `make update`, while retaining the existing OpenSpec CLI.
- Persist the container's private Nix store in a named Docker volume; do not mount or use the host Nix store or daemon.
- Add a `privileged` manifest grant to the pi-box wrapper. Nix's build sandbox needs nested namespaces, which this rootless Docker daemon only permits in privileged mode; without the grant, builds would silently run unsandboxed.
- Update project instructions to allow those targets and reserve `make os`, `make os-boot`, `make home`, `make clean`, and `make os-test` for humans. This is instruction-only; the Makefile will not gate targets.
- Document how to adopt the template in this repository, including backing up and replacing the existing ignored `Dockerfile.pi`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `pi-box-templates`: add a Nix-configs template with the toolchain, persistent private store, and enabled build sandboxing needed by this repository's allowed Makefile targets.
- `pi-box-sandbox`: add the opt-in `privileged` grant to the manifest schema.

## Impact

- Adds `home-manager/pi-box-templates/nix-configs/` and updates the repository's `AGENTS.md`, plus the `pi-box-templates` and `pi-box-sandbox` specifications.
- Changes the shared pi-box wrapper (`home-manager/pi-box.sh`) to pass `--privileged` when the manifest declares it. Template deployment and named-volume support are reused unchanged, and no host Nix configuration changes are needed.
