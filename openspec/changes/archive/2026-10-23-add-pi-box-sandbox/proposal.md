# Proposal

## Why

Pi (the coding agent) runs on this host with the full user account: it can read the AWS SSO token cache in `~/.aws/sso`, the SSH/1Password identities, and every file under `$HOME`. What is wanted instead is per-project Pi runs that start with nothing and receive only explicitly granted access. Docker Sandboxes (`sbx`) was evaluated for this and is not viable here: its local runtime requires KVM, which this VMware guest cannot expose (nested virtualization unavailable), and cloud sandboxes are excluded. Rootless Docker is already enabled on the host, so container-based isolation delivers the goal today with no new system services.

## What Changes

- Add a `pi-box` CLI wrapper (installed via home-manager) that runs Pi inside a rootless-Docker container, per project, with an explicit default grant set
- Add a managed base image (`pi-sandbox`): `node:24-slim` plus ripgrep, fd-find, git, gh, and a pinned Pi install (ordered last so version bumps do not invalidate the apt layers), plus a baked `/root/.gitconfig` that redirects the host git config's `/nix/store` credential helper to the in-container `gh` and neutralizes host-only editor/askpass settings
- Default grants per run: project workspace (rw, mounted at the same absolute path), `~/.pi/agent` (rw — shared settings, `auth.json`, sessions, skills, trust), `~/.config/git` (ro), `~/.config/gh` (ro). Explicitly never granted: `~/.aws`, `~/.ssh`, the 1Password agent socket, and any host path outside the grant set. All model-provider credentials come from the shared `~/.pi/agent/auth.json`; no credential env vars are passed
- `pi-box init` scaffolds per-project `Dockerfile.pi` and `pi-box.toml` (both untracked)
- Per-project opt-in grants via `pi-box.toml`: published ports, extra env vars (e.g. `DB_HOST=host.docker.internal` for host MySQL), extra read-only mounts, and dropping the `~/.config/gh` mount
- Automatic image builds with Docker layer caching: base image built once and shared; project images build on top so common layers are stored once and identical `Dockerfile.pi` content across worktrees builds in near-zero time
- Add `pi-box.toml` and `Dockerfile.pi` to the global gitignore (`programs.git.ignores` in `home-manager/git.nix`) so per-worktree scaffold files stay untracked
- Pilot: scaffold `Dockerfile.pi` (sury.org PHP 8.3 + php8.3-soap + composer) and `pi-box.toml` (DB host grant) in `/home/tung/code/netsuite-middleware/middleware_alpha`

## Capabilities

### New Capabilities
- `pi-box-sandbox`: Run the Pi coding agent per project inside a rootless-Docker container with least-privilege host access — an explicit default grant set, per-project opt-in grants, shared Pi identity/state, and never-granted host secrets (AWS, SSH)

### Modified Capabilities
<!-- None: no existing spec's requirements change. The gitignore addition is part of the new capability's behavior; no git capability spec exists. -->

## Impact

- `home-manager/pi-sandbox.nix` (new): installs the `pi-box` wrapper and deploys the base `Dockerfile` to `~/.pi/sandbox/`
- `home-manager/git.nix`: two new `programs.git.ignores` entries
- `home-manager/home.nix`: import the new module file
- Runtime dependencies: the existing rootless Docker daemon (no `nixos/` changes); images built on demand via `docker build`
- Outside this repo (explicitly requested scope): untracked pilot files `Dockerfile.pi` and `pi-box.toml` in `/home/tung/code/netsuite-middleware/middleware_alpha`
- Verification limited to `make home-build` per repo convention; no system-level activation
