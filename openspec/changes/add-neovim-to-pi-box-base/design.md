# Design

## Context

`home-manager/pi-sandbox.Dockerfile` builds the common `node:24-slim` image and currently installs `vim-tiny`; project images inherit this base. `home-manager/pi-box.sh` rebuilds the base with Docker caching and already has `append_config_mounts`, which mounts existing host config directories read-only and accounts for symlinked files. The wrapper currently grants only the workspace, Pi state, Git/GitHub config, and an external worktree git directory. The base image does not mount the host Nix store.

## Goals / Non-Goals

**Goals:**
- Make `nvim` available in the base and derived images and use it as Pi's Ctrl+G editor fallback.
- Expose only `~/.config/nvim`, read-only, at `/root/.config/nvim` when the host directory exists.
- Preserve the existing Git editor and all other sandbox grants.

**Non-Goals:**
- Mounting `/nix/store` or any additional host path.
- Changing the host Neovim setup, Pi's shared settings, or project-specific toolchains.
- Changing Git's `core.editor=vi` fallback.

## Decisions

- Install Debian's `neovim` package in the base image's stable OS-tooling layer and set `EDITOR=nvim` in the image. Keep `vim-tiny` because the baked Git configuration uses `vi`. Setting the environment fallback avoids editing shared Pi settings; Pi's explicit `externalEditor` setting remains authoritative over `EDITOR`.
- Reuse `append_config_mounts` for `$HOME/.config/nvim` → `/root/.config/nvim`. It skips absent directories and handles directly symlinked config files with read-only target binds, so no manifest option or new mount logic is needed. Treat this as an explicit addition to the default grant set; do not add a store-wide mount.
- Update `pi-box`'s documented default grants, `AGENTS.md`, and the common-base comments in shipped template Dockerfiles. Do not edit generated `openwiki/` pages; the repository workflow refreshes them.

## Risks / Trade-offs

- The read-only default mount makes the user's Neovim configuration readable by every pi-box project. This is the requested behavior; read-only access prevents sandboxed Neovim from changing the host configuration.
- The repository's Neovim setup is managed by Nixvim and may reference plugin/runtime files in `/nix/store`. The existing helper can bind directly symlinked config files, but no store-wide mount is added; smoke-test startup and address any unavailable plugin dependencies separately rather than exposing the host store implicitly.
- A Pi `externalEditor` setting in shared Pi state overrides `EDITOR=nvim`. This preserves existing user configuration; Ctrl+G uses Neovim by default when no such setting is configured.

## Migration Plan

1. Run `make home-build` to validate the Home Manager changes, then have the user apply the Home Manager generation.
2. The next `pi-box` run rebuilds the shared base automatically; verify `nvim --version`, the Ctrl+G editor, and the read-only config mount in a default and a derived project image.
3. To roll back, revert the Home Manager changes and apply the prior generation; the next `pi-box` run rebuilds the base from the reverted Dockerfile.
