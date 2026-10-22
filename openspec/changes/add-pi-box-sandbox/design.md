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

### Git and GitHub identity in the sandbox

Git configuration and identity travel in via read-only mounts of `~/.config/git` (with a baked `/root/.gitconfig` overriding the host's `/nix/store` credential-helper path and host-only editor/askpass settings) and `~/.config/gh`.

**Implementation finding (not anticipated in the original design):** the host's `gh` stores its token in the OS **keyring**, not in `hosts.yml` — the file carries only `git_protocol`, `user`, and `users`. A read-only `~/.config/gh` mount therefore gives `gh` its settings but no credential, and the keyring cannot be mounted without exposing every host secret. The fix is a **fine-grained read-only PAT** in `~/.pi/sandbox/gh-token` (0600), mounted read-only at `/run/pi-box/gh-token`; the container command is a `sh -c` shim that exports `GH_TOKEN` from that file and then `exec`s `pi`, so the token never appears in `docker inspect` or the host process list, and never enters the image. Mounting the whole keyring or giving the container the host's broad `gho_` token were both rejected as over-broad.

Consequence: SSH remotes (`git@github.com:...`) still cannot authenticate inside the sandbox, since that needs the 1Password agent socket, which stays excluded. Git network operations from the sandbox use HTTPS with the in-container `gh` credential helper. Per-project deploy keys remain the option if pushes from the sandbox are ever wanted.

### Default mounts and the AGENTS.md symlink fix

Home-manager deploys config files as symlinks into the Nix store, whose targets do not exist inside the container. Mounting only the directory leaves dangling links, so the wrapper also mounts each symlink's resolved target over the symlink's own container path (`~/.pi/agent/AGENTS.md`, and every symlinked entry of `~/.config/git` and `~/.config/gh`). Verified: git identity and aliases resolve, and `AGENTS.md` content matches the host byte for byte.

- `$PWD` → same absolute path, rw (session/trust path continuity)
- `~/.pi/agent` → `/root/.pi/agent`, rw (shared identity/state; `install/` rides along as inert data — the image keeps its own pinned Pi binary)
- `~/.config/git` → ro, `~/.config/gh` → ro
- The wrapper resolves `~/.pi/agent/AGENTS.md` (symlink) at runtime and bind-mounts the real file over the dangling symlink path inside the container — a file mount layered on the directory mount wins
Alternative for credential handling considered and rejected: `OPENCODE_API_KEY` env passthrough and per-project `/login` into a named volume — both superseded by the shared `auth.json` mount, which also removes any per-worktree login ritual.

### Worktree git metadata

This repo's projects use a bare-repository worktree layout, so a worktree's `.git` is a *file* holding `gitdir: <repo>/.bare/worktrees/<name>`. Mounting only the project directory severs git from its metadata, and every git command fails with `fatal: not a git repository`. **Implementation finding:** the previous default grant set was not sufficient here. `pi-box` now resolves `git rev-parse --git-common-dir` for the workspace and, when that directory lies outside the workspace, mounts it read-write at the same path. Commits update refs and reflogs under that directory, so read-only is not enough. Detection is by `.git`-file presence, so plain single-directory repositories get no extra mount, and it needs no manifest entry.

### Manifest: `pi-box.toml` parsed with `yq-go`

The manifest is the only grant mechanism beyond defaults. Schema: `ports` (list), `env` (string map), `mounts` (list of extra read-only host paths), `gh` (bool, default true). Parsing uses `yq-go` with `-p toml` (pinned in the wrapper's `runtimeInputs`), emitting TAB-separated records the shell reads into arrays. Alternatives considered: a hand-rolled `awk` parser (rejected — it mis-split a quoted value containing a comma, and had to reimplement TOML comments, CRLF, and quoting) and Python's `tomllib` (rejected only on closure size — a Python runtime for one small parse; `yq-go` is a single static binary that already has TOML support). An absent key emits no record, so the caller's defaults stand without the parser needing to supply them.

The DB grant is pure network: `env.DB_HOST = "host.docker.internal"`; the wrapper always adds `--add-host host.docker.internal:<host address>` and the database credentials already ride in the project's `.env` inside the workspace.

**Implementation finding:** rootless Docker's `host-gateway` resolves to the inner bridge address (`172.17.0.1` here), which does not reach services bound on the host — MySQL was refused until the wrapper started resolving the host's default-route source address (`ip -4 route get 1.1.1.1`) and mapping `host.docker.internal` to it, falling back to `host-gateway` when it cannot be determined.

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
- [Worktree git metadata mount widens the grant from the project directory to the repository] → Accepted deliberately: it is the same repository the workspace belongs to, and without it git is unusable in every worktree project. A per-project read-write manifest grant was the alternative; auto-detection was chosen to avoid a per-worktree footgun.
- [The GitHub token is a write-capable classic PAT (`repo` scope)] → Accepted, after fine-grained PATs proved unusable here: `Secretlabsg` enforces a ≤366-day lifetime and gates fine-grained tokens behind org approval, and the `Secretlabsg` repos never appeared in the token's selection list. Classic tokens have no read-only scope for private repos (`repo` is full control). Consequence: sandboxed Pi can push to (and administer) every repo the token reaches, which is a wider capability than the AWS/SSH boundary this change is about. Read-only alternatives, if this is revisited: a GitHub App with read-only permissions minting short-lived installation tokens, or a fine-grained PAT approved by an org admin. Deleting `~/.pi/sandbox/gh-token` removes the capability entirely.
- [`node:24-slim` pulls hit Docker Hub limits] → The daemon already uses a registry mirror (`mirror.gcr.io`).

## Migration Plan

1. Add `home-manager/pi-sandbox.nix`, import it in `home.nix`, add the two ignore entries in `git.nix`
2. Verify with `make home-build`; the user applies with `make home`
3. `pi-box init` in `/home/tung/code/netsuite-middleware/middleware_alpha` (Dockerfile.pi: sury repo, `php8.3`, `php8.3-soap`, composer; pi-box.toml: `DB_HOST` env grant)
4. First `pi-box` run builds base + project images and starts the session; run the pilot verification list (see tasks.md)
5. Rollback: remove the module import and file, revert the ignore entries, `docker rmi pi-sandbox pi-middleware_alpha`; the pilot scaffold files are untracked and can simply be deleted
