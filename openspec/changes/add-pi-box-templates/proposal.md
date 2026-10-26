# Proposal

## Why

`pi-box init` only ever writes one generic Dockerfile with a commented PHP example, so every real project needs a hand-crafted `Dockerfile.pi` repeated across worktrees (today only `middleware_alpha` has one), and sandboxed Maven builds re-download the entire dependency tree on every run because the container is `--rm`. Templates make a fresh worktree one command away from a working sandbox, and a persistent named volume fixes the Maven cache without touching host state.

## What Changes

- New template catalog deployed declaratively by home-manager to `~/.pi/sandbox/templates/` from `home-manager/pi-box-templates/`:
  - `php83` — sury PHP 8.3 + composer + `bcmath cli curl dom gd mbstring mysql soap xml zip`, manifest with `DB_HOST = "host.docker.internal"`
  - `php82` — same extension list on sury PHP 8.2, same manifest
  - `java8` — Temurin 8 JDK + Maven 3.6.3, manifest declaring a named Docker volume for `/root/.m2` so the Maven cache persists across runs
  - `node22` — Node 22 (>= 22.19, satisfies pi's engines) + yarn classic 1.22.x
  - `default` — today's generic files, unchanged
- `pi-box init [--force] [template]` — optional template name, `--list` prints available templates, unknown name fails with the list. A template may ship its own `pi-box.toml`; otherwise the generic manifest is written.
- New manifest grant `volumes = [...]` (named Docker volumes passed through as `--volume`).
- Init overwrite behavior: when target files exist, one prompt for the whole batch; on yes each existing file is backed up to `<file>.<YYYYmmdd-HHMMSS>.bak` (one shared timestamp per init run) before writing. Non-interactive runs leave files alone; `-f/--force` backs up and overwrites without prompting.

## Capabilities

### New Capabilities

- `pi-box-templates`: the pi-box template catalog — which templates are shipped, what toolchain each provides, and where templates live.

### Modified Capabilities

- `pi-box-sandbox`: template selection in the scaffold, overwrite-with-backup semantics (replaces "leave existing files untouched"), and the named-volume grant in the manifest.

## Impact

- `home-manager/pi-sandbox.nix` — deploy templates via `home.file`
- `home-manager/pi-box.sh` — init template selection and backup logic, `volumes` manifest key, usage text
- `home-manager/pi-box-templates/` — new directory, five templates
- `AGENTS.md` — pi-box section: template list, init flags, backup behavior, Maven volume
- No changes to any project repository; existing `Dockerfile.pi` / `pi-box.toml` files stay valid
