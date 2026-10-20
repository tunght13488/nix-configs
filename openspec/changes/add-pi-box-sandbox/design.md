# Design

## Context

The host is a VMware guest (`nixos-vmware`) with no KVM (`/proc/cpuinfo` lacks `vmx`, nested virtualization unavailable), which rules out microVM-based agents (Docker Sandboxes `sbx`, Kata, QEMU-with-KVM). Rootless Docker 29.7.2 is already enabled in `nixos/configuration.nix` with DNS and a registry mirror configured, and is the isolation boundary this change builds on. Host state that must stay outside the sandbox: AWS SSO token cache (`~/.aws/sso`), SSH identities and the 1Password agent socket. Host state that is deliberately shared: Pi identity/state (`~/.pi/agent`, whose only secret-bearing file is `auth.json`) and git/GitHub configuration (`~/.config/git`, `~/.config/gh`). See proposal.md - Why for the motivation.

Constraints from the environment that shape the design:

- Host `~/.config/git/config` contains host-only references: credential helper at a `/nix/store/...-gh/bin/gh` path, `core.editor = nvim`, `core.askpass = git-gui--askpass`, diff/merge tools set to `vscode`
- Host `~/.pi/agent/AGENTS.md` is a home-manager symlink into `/nix/store`, which dangles inside a container
- Pi sessions and `trust.json` key on absolute `/home/tung/code/...` paths, so mounting the workspace at the same absolute path preserves session and trust continuity
- The pilot project (`middleware_alpha`) is PHP 8.3 / Laravel 11 with MySQL-backed feature tests; Debian bookworm does not ship PHP 8.3 in its default repos

## Goals / Non-Goals

**Goals:**
- One-command sandboxed Pi per project with a grant set that is explicit, minimal by default, and extendable per project without editing the wrapper
- Zero per-sandbox login: all model credentials via the shared `~/.pi/agent/auth.json`
- Common toolchain baked once in a shared base image; project images stay thin
- Repo changes limited to home-manager; no `nixos/` changes, no new system services

**Non-Goals:**
- Egress/network allowlisting (plain Docker gives open outbound; revisit via OpenShell if ever needed)
- gVisor/`runsc` hardening (namespace boundary accepted as sufficient)
- Any AWS access from inside a sandbox (explicitly deferred)
- Nix-built images (`dockerTools`); toolchains come from Debian/sury packages in per-project Dockerfiles
- Multi-container setups (sidecar DB); the host MySQL is the database target

## Decisions

### Isolation: existing rootless Docker, not sbx / OpenShell / Gondolin

Alternatives considered: Docker Sandboxes (`sbx`) — requires KVM, impossible here; cloud sandboxes — excluded (local only); OpenShell — policy-first fit but adds a gateway daemon and early 0.0.x packaging for needs (egress policy, credential vault) this design does not have; Gondolin — QEMU TCG without KVM is slow and it routes tools only, keeping the Pi process on the host. Rootless Docker is already running, and its user namespace maps container-root to the host user, so workspace writes land as the invoking user with no permission handling.

### Delivery: home-manager shell wrapper + plain Dockerfiles

`pi-box` is a shell script installed via home-manager (`writeShellApplication`-style in `home-manager/pi-sandbox.nix`); the base `Dockerfile` is deployed by the same module to `~/.pi/sandbox/Dockerfile` via `home.file`. Alternatives: packaging `pi-box` as a Nix package in `pkgs/` (rejected for now — it is personal tooling, not a reusable package); building the base image with `dockerTools` (rejected — per-project Dockerfiles were chosen, and apt-based toolchains are simpler than Nix closures for this).

### Base image layout (commons first, volatile last)

`FROM node:24-slim`, then `apt-get install ripgrep fd-find git gh`, then `/root/.gitconfig` overrides, then the pinned Pi install last (`ARG PI_VERSION`). Ordering rationale: a Pi version bump invalidates only the final layer, never the apt layers. The baked `/root/.gitconfig` (which takes precedence over the XDG global config that arrives via the `~/.config/git` mount) resets `credential.helper` for `https://github.com` to the in-container `gh auth git-credential` and neutralizes `core.editor`/`core.askpass` to container-safe values.

### Per-project image: `FROM pi-sandbox` + `Dockerfile.pi`

`pi-box` derives the image tag from the directory name (`pi-<dirname>`), so worktrees get distinct images while sharing base layers. BuildKit's cache is shared across builds: identical `Dockerfile.pi` content in two worktrees means the second build is a near-no-op. The wrapper simply always runs `docker build` (base, then project) — cache makes unchanged builds instant, and a changed `Dockerfile.pi` invalidates exactly its own layers. No hash tracking.

### Default mounts and the AGENTS.md symlink fix

- `$PWD` → same absolute path, rw (session/trust path continuity)
- `~/.pi/agent` → `/root/.pi/agent`, rw (shared identity/state; `install/` rides along as inert data — the image keeps its own pinned Pi binary)
- `~/.config/git` → ro, `~/.config/gh` → ro
- The wrapper resolves `~/.pi/agent/AGENTS.md` (symlink) at runtime and bind-mounts the real file over the dangling symlink path inside the container — a file mount layered on the directory mount wins

Alternative for credential handling considered and rejected: `OPENCODE_API_KEY` env passthrough and per-project `/login` into a named volume — both superseded by the shared `auth.json` mount, which also removes any per-worktree login ritual.

### Manifest: `pi-box.toml` with a tiny schema

The manifest is the only grant mechanism beyond defaults. Schema: `ports` (list), `env` (string map), `mounts` (list of extra read-only host paths), `gh` (bool, default true). The wrapper parses it with a few lines of shell (`grep`/`sed`-level TOML for this flat schema) — no parser dependency. The DB grant is pure network: `env.DB_HOST = "host.docker.internal"`; the wrapper always adds `--add-host host.docker.internal:host-gateway` (rootless Docker proxies host-bound connections through the host userspace, reaching MySQL on host loopback), and the database credentials already ride in the project's `.env` inside the workspace.

### Gitignore entries in `programs.git.ignores`

`pi-box.toml` and `Dockerfile.pi` are added to `programs.git.ignores` in `home-manager/git.nix`. This generates `~/.config/git/ignore`, so both the host and every container (via the `~/.config/git` mount) ignore the scaffold files — one change covers both sides.

### `pi-box init`

Embedded templates in the wrapper write `Dockerfile.pi` and `pi-box.toml` when absent, never overwrite. This is the new-worktree ritual: `pi-box init` then `pi-box` — no login, since auth is shared.

## Risks / Trade-offs

- [A rogue sandboxed agent can read or mutate the shared `auth.json` and shared Pi state] → Accepted boundary: the sandbox receives Pi's identity but never the OS identity (AWS, SSH). Consistent with the stated priority (AWS protection).
- [NixOS-installed Pi packages/extensions (`pi-subagents`, `pi-web-access`, `@plannotator/pi-extension`, `powerline-footer`) may fail on the image's Debian node if they contain native addons] → Verify at pilot; fallback is baking the affected package into the base image or excluding it per project.
- [Host Pi version drifts from the image's pinned Pi] → Rebuild the base image when upgrading Pi; surfaced as a note in `pi-box` output/help.
- [`gh` under a read-only `~/.config/gh` mount may attempt writes on some flows] → Verify at pilot; fallback is mounting rw or dropping per project.
- [MySQL account host matching for slirp-proxied container connections (`tung`@`localhost` vs `tung`@`%`)] → Verify at pilot; fix the account host pattern if needed.
- [Host and container Pi writing shared state concurrently] → Sessions are separate files per session; `trust.json`/`settings.json` writes are rare. Accepted.
- [`node:24-slim` pulls hit Docker Hub limits] → The daemon already uses a registry mirror (`mirror.gcr.io`).

## Migration Plan

1. Add `home-manager/pi-sandbox.nix`, import it in `home.nix`, add the two ignore entries in `git.nix`
2. Verify with `make home-build`; the user applies with `make home`
3. `pi-box init` in `/home/tung/code/netsuite-middleware/middleware_alpha` (Dockerfile.pi: sury repo, `php8.3`, `php8.3-soap`, composer; pi-box.toml: `DB_HOST` env grant)
4. First `pi-box` run builds base + project images and starts the session; run the pilot verification list (see tasks.md)
5. Rollback: remove the module import and file, revert the ignore entries, `docker rmi pi-sandbox pi-middleware_alpha`; the pilot scaffold files are untracked and can simply be deleted
