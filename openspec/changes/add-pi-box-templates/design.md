# Design

## Context

`pi-box` is a shell application built from `home-manager/pi-box.sh` by `home-manager/pi-sandbox.nix` (PI_VERSION substituted at build time). The base image Dockerfile is deployed to `~/.pi/sandbox/Dockerfile` as a symlink into the Nix store and built on demand. `cmd_init` currently writes two hardcoded heredoc templates and never overwrites existing files. The manifest is parsed by `yq` in `parse_manifest`; extra mounts are passed read-only (`--volume "$item:$item:ro"`). `cmd_run` rebuilds base + project images on every run, relying on layer caching. The base image is Debian bookworm with Node 24 (pi requires Node >= 22.19) and no PHP/JDK/Maven.

## Goals / Non-Goals

**Goals:**

- One-command scaffolding for the five known project stacks
- Persistent Maven cache without touching host state
- Safe overwrite with recoverable backups

**Non-Goals:**

- Writable host-path mounts (rejected on isolation grounds; named volumes instead)
- Template parameterization or variables — templates are static files, versions baked in
- Auto-detecting the project stack from repo content
- Changes to the base image or to run-time grants beyond `volumes`

## Decisions

### 1. Templates live in the repo, deployed declaratively

Source: `home-manager/pi-box-templates/<name>/`; deployed via `home.file.".pi/sandbox/templates/<name>/..."` to `~/.pi/sandbox/templates/`. Same pattern as the base Dockerfile: versioned with the config, one `make home` to update.

*Alternatives*: hand-managed files in `~/.pi/sandbox/` (not versioned, lost on rebuild — rejected); shipping templates inside `pi-box.sh` heredocs (script bloat, still needs deployment anyway — rejected).

Deployed files are symlinks into the Nix store; `cmd_init` copies with `cp` (follows symlinks), never `readlink`+copy. Hand-editing a deployed template is intentionally overwritten by the next switch — the repo is the source of truth.

### 2. Single copy path in init

The generic heredocs move into `templates/default/` so `cmd_init` always copies from a template directory: resolve name (empty → `default`), validate the directory exists (else `die` with the list), copy `Dockerfile.pi`, copy the template's `pi-box.toml` when present (else `default`'s manifest). The `SC2016` shellcheck exclusion for the removed literals is dropped.

CLI: `pi-box init [--force] [template]`, `pi-box init --list` (names to stdout). Unknown template exits non-zero with the list; nothing is written. `--force` combined with no name applies to `default`.

### 3. Backup on overwrite

One timestamp per init run: `stamp="$(date +%Y%m%d-%H%M%S)"` computed once, used for every backup so backups from one run are recognizable as a batch. Existing files are detected first; interactive sessions get one prompt for the whole batch. On yes (or `--force`): `cp -a "$file" "$file.$stamp.bak"` then write the template (plain `printf >` truncates). On no, or without a terminal: leave files alone, as today.

*Alternatives*: per-file prompts (defeats the shared-stamp intent); `mv` instead of `cp` (original would be gone if the template write fails — rejected); numbered counter for same-second collisions (accepted risk, `shortcut:` comment).

### 4. Named Docker volumes instead of a host m2 mount

New manifest key: `volumes = ["pi-m2-example:/root/.m2"]`. `parse_manifest` emits a `VOLUME` record; `cmd_run` passes `--volume "$item"` unchanged — Docker creates and owns the volume under the rootless daemon. Per-project names (`pi-m2-<project>`) keep caches isolated; a `shortcut:` comment documents that dead projects leave volumes behind (`docker volume rm`).

*Alternatives*: rw-mounting host `~/.m2` (would need a new rw-mount feature anyway, plus cross-project write channel, races with host builds, and future `settings.xml` credentials — rejected); `MAVEN_OPTS=-Dmaven.repo.local=.pi-box/m2` (zero code but cwd-sensitive: cache silently splits when mvn runs from a subdirectory, and pollutes the repo tree — rejected); baking `dependency:go-offline` into the image (slow pom-change rebuilds, incomplete coverage — rejected).

### 5. Template contents

- **php83**: middleware's proven Dockerfile (sury repo, `composer` + `bcmath cli curl dom mbstring mysql soap xml zip`) plus `php8.3-gd` (v3 requires gd). `pcntl`, `posix`, `sodium`, `fileinfo` ship in sury's cli package (verified against the built `pi-middleware_alpha` image). Manifest: `DB_HOST = "host.docker.internal"` — Laravel's dotenv is immutable, so the container env var wins over `.env`.
- **php82**: same package list on sury 8.2, same manifest. prbot keeps resolving as platform 8.2 via its own composer config; proxy's Laravel 9 stays on the PHP it was built for.
- **java8**: Temurin 8 JDK from the Adoptium apt repo (bookworm has no Java 8) + Maven 3.6.3 tarball from `archive.apache.org` to `/opt`, `mvn` symlinked into `/usr/local/bin`, `JAVA_HOME=/usr/lib/jvm/temurin-8-jdk-amd64`. Manifest: `volumes = ["pi-m2-<project>:/root/.m2"]` with a comment documenting optional one-way seeding from the host cache (`docker run ... cp -a`). Cold first run accepted.
- **node22**: official Node 22.23.4 tarball extracted over `/usr/local` (shadows the base Node 24; 22.23.4 >= 22.19 so pi still runs), then `npm install -g yarn@1.22.22`. No manifest of its own.
- **default**: today's generic Dockerfile (commented PHP example) and generic manifest, moved verbatim.

### 6. Docs

`AGENTS.md` pi-box section gains: template list with per-template intent, `init [--force] [template]` / `--list` usage, backup naming and the shared timestamp, and the `volumes` grant with the Maven-volume example.

## Risks / Trade-offs

- [Temurin 8 deb missing on bookworm] → verify during the first build; fallback is the Adoptium tarball install.
- [Fluent maven repo unreachable from the sandbox] → verify on first `mvn test`; the project's own AGENTS.md already documents the reference-jar fallback.
- [Same-second re-init clobbers the previous backup] → accepted, `shortcut:` comment.
- [Node 22 pinned to 22.23.4] → deliberate; bump the template when the project moves versions.
- [Volumes accumulate] → documented prune command; per-project names keep them identifiable.
- [Templates deployed as store symlinks] → `cp` follows symlinks; covered in task verification.

## Migration Plan

1. `make home` to deploy the template directory (verification step, run by the user).
2. Existing projects keep their files untouched; adopting a template is `pi-box init --force <template>` in that worktree (backups created first).
3. `middleware_alpha`'s current `Dockerfile.pi` remains valid — it is the source of the php83 template, no project-side change needed.
