# Spec Delta

## Purpose

Runs the Pi coding agent per project inside a rootless-Docker container with least-privilege host access: an explicit default grant set, per-project opt-in grants, shared Pi identity and state, and never-granted host secrets such as AWS and SSH credentials.

## ADDED Requirements

### Requirement: Per-project sandboxed Pi session

Running `pi-box` in a project directory SHALL start an interactive Pi session in a container with that directory mounted read-write at its host absolute path as the working directory. The container SHALL run under the existing rootless Docker daemon.

#### Scenario: Launch from project root
- **WHEN** `pi-box` is run inside a project directory
- **THEN** Pi's TUI starts in a container whose working directory is the project, mounted at the same absolute path as on the host

#### Scenario: Workspace writes reach the host
- **WHEN** sandboxed Pi creates or edits a file in the workspace
- **THEN** the change is immediately visible at the same path on the host

#### Scenario: Container files owned by the host user
- **WHEN** a process inside the container creates a file in the workspace
- **THEN** the file is owned by the invoking host user, not a foreign uid

### Requirement: Least-privilege default grant set

By default the sandbox SHALL receive exactly these host resources: the project workspace (read-write), `~/.pi/agent` (read-write), `~/.config/git` (read-only), and `~/.config/gh` (read-only). The sandbox SHALL NOT receive `~/.aws`, `~/.ssh`, the 1Password agent socket, or any other host path.

#### Scenario: AWS credentials inaccessible
- **WHEN** a process in the sandbox reads `~/.aws` (including the SSO token cache)
- **THEN** the path does not exist inside the sandbox

#### Scenario: SSH identities inaccessible
- **WHEN** a process in the sandbox reads `~/.ssh` or the 1Password agent socket
- **THEN** the paths do not exist inside the sandbox

#### Scenario: Only granted paths are mounted
- **WHEN** the container's mounts are inspected on a default run
- **THEN** the host-backed mounts are exactly the workspace, `~/.pi/agent`, `~/.config/git`, and `~/.config/gh`

### Requirement: Shared Pi identity, state, and instructions

The sandbox SHALL use the host's `~/.pi/agent` read-write as its Pi state: provider credentials from `auth.json`, settings, sessions, skills, and trust decisions are shared with host Pi. No provider credential SHALL be passed to the container through environment variables. The global `~/.pi/agent/AGENTS.md` (a symlink into the Nix store on the host) SHALL be readable inside the sandbox.

#### Scenario: No credential environment variables
- **WHEN** the container environment is inspected
- **THEN** it contains no provider API key or OAuth token variables

#### Scenario: Model access without per-sandbox login
- **WHEN** sandboxed Pi makes a provider request using a provider already authenticated on the host
- **THEN** the request authenticates via the shared `auth.json` without any login step in the sandbox

#### Scenario: State changes propagate to the host
- **WHEN** sandboxed Pi records a session, setting, or trust decision
- **THEN** the same state is visible to host Pi on its next run

#### Scenario: Global instructions readable
- **WHEN** sandboxed Pi reads its global `AGENTS.md`
- **THEN** the content matches the host's global Pi instructions, despite the host-side symlink pointing into the Nix store

### Requirement: Git and GitHub identity in the sandbox

The sandbox SHALL carry the host's git and GitHub configuration via read-only mounts of `~/.config/git` and `~/.config/gh`. Host-only references inside that configuration (the `/nix/store` credential helper path, host editor, askpass, and diff/merge tools) SHALL be neutralized or redirected to in-container equivalents.

#### Scenario: Commits carry host identity
- **WHEN** a commit is created inside the sandbox
- **THEN** the author name and email match the host git configuration

#### Scenario: gh can read pull requests
- **WHEN** `gh pr view` runs inside the sandbox
- **THEN** it authenticates using the host gh configuration and returns the pull request details

#### Scenario: Git over HTTPS uses the in-container credential helper
- **WHEN** git authenticates against `https://github.com` inside the sandbox
- **THEN** it uses the in-container `gh auth git-credential` helper rather than the host's `/nix/store` helper path

#### Scenario: Host-only tools are not invoked
- **WHEN** git requires an editor or credential prompt inside the sandbox
- **THEN** it uses container-safe fallbacks instead of `nvim`, `vscode`, or `git-gui--askpass`

### Requirement: Per-project opt-in grants via manifest

A per-project manifest (`pi-box.toml`) SHALL be the only mechanism for granting resources beyond the default set. Supported grants SHALL be: published ports, extra environment variables, extra read-only mounts, and disabling the `~/.config/gh` mount. Grants not declared in the manifest SHALL NOT be present.

#### Scenario: Host database access
- **WHEN** the manifest sets `DB_HOST=host.docker.internal` and the sandbox runs the project's feature tests
- **THEN** the tests connect to the host's MySQL and no database credentials are duplicated in the manifest

#### Scenario: Dropping the GitHub identity
- **WHEN** the manifest disables the gh mount
- **THEN** `~/.config/gh` is not present inside the sandbox

#### Scenario: Undeclared grants are absent
- **WHEN** the manifest declares no ports, env vars, or extra mounts
- **THEN** the container publishes no ports and carries no extra grants

### Requirement: Project scaffold creation

`pi-box init` SHALL create `Dockerfile.pi` and `pi-box.toml` in the current project directory from templates when they do not exist, and SHALL leave existing files untouched. Both files SHALL be ignored by the user's global gitignore so they remain untracked in every repository.

#### Scenario: Scaffold a new worktree
- **WHEN** `pi-box init` runs in a project without the scaffold files
- **THEN** both `Dockerfile.pi` and `pi-box.toml` are created from templates

#### Scenario: Idempotent scaffold
- **WHEN** `pi-box init` runs in a project that already has the scaffold files
- **THEN** the existing files are not modified

#### Scenario: Scaffolds stay untracked
- **WHEN** `git status` runs in any repository containing `Dockerfile.pi` or `pi-box.toml`
- **THEN** neither file appears as untracked

### Requirement: Automatic image build with shared common layers

`pi-box` SHALL automatically build the required images before starting the sandbox, using Docker layer caching: a base image holding the common toolchain (built once and shared) and a thin per-project image built from the project's `Dockerfile.pi`. The base image SHALL order its layers stable-first so a Pi version bump does not invalidate the common layers. An unchanged `Dockerfile.pi` SHALL produce a near-instant cached rebuild; a changed one SHALL rebuild only the project layers.

#### Scenario: First run builds images
- **WHEN** `pi-box` runs and the base or project image does not exist
- **THEN** the missing images are built automatically before the container starts

#### Scenario: Identical scaffold across worktrees reuses layers
- **WHEN** a second worktree builds a project image with `Dockerfile.pi` content identical to another worktree's
- **THEN** the build completes with reused cached layers and stores no duplicate common layers

#### Scenario: Dockerfile change rebuilds only project layers
- **WHEN** the project's `Dockerfile.pi` is edited
- **THEN** the next `pi-box` run rebuilds the project image while reusing the base image layers
