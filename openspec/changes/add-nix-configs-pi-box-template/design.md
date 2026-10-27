# Design

## Context

See proposal.md for motivation. The current project-root `Dockerfile.pi` is globally ignored and installs OpenSpec 1.14.1 on top of `pi-sandbox`, but not Nix. The shared base is Debian-based and intentionally has no Nix store or host Nix access. The pi-box wrapper already deploys template directories recursively and supports named Docker volumes through `pi-box.toml`.

The Makefile's non-human targets are `format` (also the default target), `home-build`, `os-build`, and `update`. The `os`, `os-boot`, `home`, `clean`, and `os-test` targets are reserved for human use by project instructions only.

## Goals / Non-Goals

**Goals:**
- Provide a reproducible project-specific image with the commands needed by the non-human Makefile targets and the existing OpenSpec CLI.
- Keep Nix state persistent between disposable pi-box runs without sharing the host store or daemon.
- Make the command policy explicit in the project instructions without changing Makefile behavior.

**Non-Goals:**
- Adding Nix to the shared `pi-sandbox` base or changing the pi-box wrapper's grant model.
- Enforcing the human-only target policy in `Makefile` or technically hiding the binaries those targets use.
- Running `make os-test` in the container or applying any Home Manager/NixOS configuration from it.

## Decisions

### Add a project-specific template

Add `home-manager/pi-box-templates/nix-configs/` rather than expanding the shared base. Its Dockerfile extends `pi-sandbox`, retains the current OpenSpec CLI pin, and supplies Nix with flakes, `make`, `nh`, `nixos-rebuild`, `nixpkgs-fmt`, and the core utilities used by the Makefile. The existing recursive Home Manager deployment already publishes new template directories, so the wrapper and module need no changes.

### Keep the Nix store private and persistent

The template manifest declares a named volume at `/nix`. This retains the container's Nix store and database across `docker run --rm` sessions while keeping host `/nix` and the host daemon socket outside the sandbox. The volume is scoped to this Nix-configs workflow and can be removed independently of host Nix state.

### Keep the human-only rule in instructions

Update `AGENTS.md` to permit the four non-human targets and reserve the five named targets for humans. Do not add Makefile checks: `nh` and `nixos-rebuild` are required for allowed build targets, so their binaries cannot distinguish the reserved targets. The reservation is intentionally agent guidance, not a technical access-control boundary.

### Adopt through the existing scaffold command

After Home Manager deploys the template, use `pi-box init --force nix-configs` in this worktree to back up the existing ignored `Dockerfile.pi` and create the template's Dockerfile and manifest. The template sources must be force-added to Git because the global ignore rules cover the scaffold filenames and Nix evaluation only sees tracked inputs.

## Risks / Trade-offs

- [Nix builds may not be able to create their normal build sandbox inside rootless Docker] -> Validate evaluation and build targets with Nix sandboxing enabled. Do not silently disable Nix sandboxing or fall back to the host daemon/store; if nested sandboxing fails, stop and revisit the isolation design.
- [The named Nix volume consumes disk and outlives the sandbox container] -> Document the volume name and how a human can remove it when the Nix-configs sandbox is retired.
- [Instruction-only reservations can be ignored or bypassed by shell commands] -> Accepted per the user's policy choice; the container still receives no host Nix store or daemon access.
- [The existing project-root scaffold is ignored and will not update when the template changes] -> Adoption uses `pi-box init --force`, which creates a timestamped backup before replacing it.

## Migration Plan

1. Add and force-add the new template files; update the template spec and `AGENTS.md` command policy.
2. Run the allowed `make home-build` target to validate Home Manager evaluation. A human applies the Home Manager generation so the template is deployed.
3. In this worktree, run `pi-box init --force nix-configs`; verify the prior ignored Dockerfile was backed up and the Nix volume manifest was created.
4. Build and launch the project image. Verify OpenSpec and the Nix/Makefile tools are available, then run `make format`, `make home-build`, `make os-build`, and `make update` as needed. Verify Nix state persists across runs and no host Nix path or daemon socket is mounted.
5. Roll back by reinitializing from the prior scaffold backup and removing the named Docker volume if desired; remove the Home Manager template and its documentation/spec delta to revert the repository change.
