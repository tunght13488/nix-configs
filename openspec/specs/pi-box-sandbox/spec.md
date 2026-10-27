# pi-box-sandbox Specification

## Purpose

Runs the Pi coding agent per project inside a rootless-Docker container with least-privilege host access: an explicit default grant set, per-project opt-in grants, shared Pi identity and state, and never-granted host secrets such as AWS and SSH credentials.

## Requirements

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

By default the sandbox SHALL receive exactly these host resources: the project workspace (read-write), `~/.pi/agent` (read-write), `~/.config/git` (read-only), `~/.config/gh` (read-only), and — when the project is a git worktree or submodule whose git common directory lies outside the workspace — that git directory (read-write). The sandbox SHALL NOT receive `~/.aws`, `~/.ssh`, the 1Password agent socket, or any other host path.

#### Scenario: AWS credentials inaccessible
- **WHEN** a process in the sandbox reads `~/.aws` (including the SSO token cache)
- **THEN** the path does not exist inside the sandbox

#### Scenario: SSH identities inaccessible
- **WHEN** a process in the sandbox reads `~/.ssh` or the 1Password agent socket
- **THEN** the paths do not exist inside the sandbox

#### Scenario: Only granted paths are mounted
- **WHEN** the container's mounts are inspected on a default run
- **THEN** the host-backed mounts are exactly the workspace, `~/.pi/agent`, `~/.config/git`, `~/.config/gh`, plus the project's git directory when it lives outside the workspace

#### Scenario: Git metadata outside the workspace is usable
- **WHEN** the project is a worktree in a bare-repository layout and `git status`, `git log`, or a commit runs inside the sandbox
- **THEN** the command succeeds against the same repository as on the host

#### Scenario: Plain project adds no extra mount
- **WHEN** the project's `.git` is a directory inside the workspace
- **THEN** no git directory is mounted beyond the workspace

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

The sandbox SHALL carry the host's git and GitHub configuration via read-only mounts of `~/.config/git` and `~/.config/gh`, and SHALL neutralize or redirect host-only references inside that configuration (the `/nix/store` credential helper path, host editor, askpass, and diff/merge tools) to in-container equivalents.

#### Scenario: Commits carry host identity
- **WHEN** a commit is created inside the sandbox
- **THEN** the author name and email match the host git configuration

#### Scenario: Git over HTTPS uses the in-container credential helper
- **WHEN** git authenticates against `https://github.com` inside the sandbox
- **THEN** it uses the in-container `gh auth git-credential` helper rather than the host's `/nix/store` helper path

#### Scenario: Host-only tools are not invoked
- **WHEN** git requires an editor or credential prompt inside the sandbox
- **THEN** it uses container-safe fallbacks instead of `nvim`, `vscode`, or `git-gui--askpass`

### Requirement: GitHub authentication in the sandbox

Because the host's `gh` keeps its credential in the OS keyring, which does not cross the sandbox boundary, the sandbox SHALL authenticate `gh` through a read-only mounted token file. The token SHALL NOT be passed through the container environment or appear in `docker inspect`.

#### Scenario: gh can read pull requests
- **WHEN** `gh pr view` runs inside the sandbox with a token file present
- **THEN** it authenticates with that token and returns the pull request details

#### Scenario: Token stays out of the container environment
- **WHEN** the container environment and configuration are inspected
- **THEN** the GitHub token appears only in the read-only mounted file, not in environment variables

#### Scenario: Missing token file leaves gh unauthenticated
- **WHEN** no token file exists
- **THEN** the sandbox still starts and `gh` reports an authentication failure instead of failing the run

### Requirement: Per-project opt-in grants via manifest

A per-project manifest (`pi-box.toml`) SHALL be the only mechanism for granting resources beyond the default set. Supported grants SHALL be: published ports, extra environment variables, extra read-only mounts, named Docker volumes, and disabling the `~/.config/gh` mount. Grants not declared in the manifest SHALL NOT be present.

#### Scenario: Host database access
- **WHEN** the manifest sets `DB_HOST=host.docker.internal` and the sandbox runs the project's feature tests
- **THEN** the tests connect to the host's MySQL and no database credentials are duplicated in the manifest

#### Scenario: Dropping the GitHub identity
- **WHEN** the manifest disables the gh mount
- **THEN** `~/.config/gh` is not present inside the sandbox

#### Scenario: Named volume persists across runs
- **WHEN** the manifest declares `volumes = ["pi-m2-example:/root/.m2"]` and a sandbox run writes files under `/root/.m2`
- **THEN** a later sandbox run of the same project finds those files through the same volume

#### Scenario: Undeclared grants are absent
- **WHEN** the manifest declares no ports, env vars, volumes, or extra mounts
- **THEN** the container publishes no ports, mounts no volumes, and carries no extra grants

### Requirement: Project scaffold creation

`pi-box init [--force] [template]` SHALL create `Dockerfile.pi` and `pi-box.toml` in the current project directory from the named template, or from the default template when no name is given. Existing files SHALL be backed up with a shared timestamp before being overwritten, and only when the user confirms interactively or `--force` is passed; otherwise they SHALL be left untouched. Both files SHALL be ignored by the user's global gitignore so they remain untracked in every repository.

#### Scenario: Scaffold a new worktree
- **WHEN** `pi-box init` runs in a project without the scaffold files
- **THEN** both `Dockerfile.pi` and `pi-box.toml` are created from the default template

#### Scenario: Scaffold with a named template
- **WHEN** `pi-box init php83` runs in a project without the scaffold files
- **THEN** `Dockerfile.pi` matches the php83 template and `pi-box.toml` matches the template's manifest

#### Scenario: Templates are listable
- **WHEN** `pi-box init --list` runs
- **THEN** the available template names are printed

#### Scenario: Unknown template fails with the list
- **WHEN** `pi-box init nosuchtemplate` runs
- **THEN** init exits non-zero without writing anything and prints the available template names

#### Scenario: Interactive overwrite backs up first
- **WHEN** `pi-box init` runs in a project with existing scaffold files and the user answers yes to the single prompt
- **THEN** each existing file is copied to `<file>.<YYYYmmdd-HHMMSS>.bak`, all backups from that run sharing the same timestamp, and the new files are written

#### Scenario: Idempotent scaffold
- **WHEN** `pi-box init` runs in a project that already has the scaffold files and the user answers no
- **THEN** the existing files are not modified

#### Scenario: Non-interactive init never overwrites
- **WHEN** `pi-box init` runs without a terminal in a project with existing scaffold files
- **THEN** the existing files are not modified

#### Scenario: Force overwrites without prompting
- **WHEN** `pi-box init --force php83` runs in a project with existing scaffold files
- **THEN** the existing files are backed up with a shared timestamp and the template files are written without any prompt

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

### Requirement: GitHub SCP-style SSH remotes work without SSH credentials

Git operations in the sandbox that target GitHub using SCP-style SSH URLs SHALL transparently use HTTPS and the existing in-container GitHub credential helper. This SHALL NOT require mounting SSH identities or changing the repository's configured remote URL.

#### Scenario: Fetch through a GitHub SSH-form remote
- **WHEN** `git fetch`, `git ls-remote`, or a clone targets `git@github.com:ORG/REPO.git` and the sandbox has a valid GitHub token
- **THEN** the operation succeeds over HTTPS using the in-container credential helper without an SSH agent

#### Scenario: Existing remote configuration remains unchanged
- **WHEN** a Git operation uses an SSH-form GitHub remote in the sandbox
- **THEN** the configured remote URL remains `git@github.com:ORG/REPO.git`

#### Scenario: Other SSH hosts are not rewritten
- **WHEN** a Git operation targets an SSH URL for a host other than `github.com`
- **THEN** the sandbox does not rewrite that URL as a GitHub HTTPS URL

### Requirement: Python 3 interpreter in the shared base image
The shared `pi-sandbox` image SHALL provide a Python 3 interpreter available as `python3` in both the base image and project images derived from it.

#### Scenario: Python runs in the base image
- **WHEN** `python3 --version` runs in a sandbox using the base image
- **THEN** it succeeds and reports a Python 3 version

#### Scenario: Python is inherited by project images
- **WHEN** `python3 --version` runs in a sandbox using a project image derived from `pi-sandbox`
- **THEN** it succeeds and reports a Python 3 version without project-specific Python installation

### Requirement: Herdr agent state reporting through a filtered relay

When `pi-box` runs inside a herdr pane, the sandbox SHALL report Pi's working, blocked, and idle states to herdr through a filtered host-side relay. The sandbox SHALL NOT receive the herdr API socket, and the relay SHALL forward only the two agent state report methods, with the pane id forced to the host pane's.

#### Scenario: Sandboxed pane reports real agent states

- **WHEN** `pi-box` is started in a herdr pane and the sandboxed Pi session begins, works, and blocks on user input
- **THEN** the herdr agent sidebar shows working, blocked, and idle at the matching moments, as it does for a host Pi pane

#### Scenario: Relay forwards only report methods

- **WHEN** a process inside the sandbox connects to the socket path published to it and sends a method other than `pane.report_agent` or `pane.report_agent_session`
- **THEN** the method is not forwarded to herdr and reaches no herdr API

#### Scenario: Herdr API socket is not mounted

- **WHEN** the container's mounts are inspected on a run inside a herdr pane
- **THEN** the herdr API socket path is not present; only the relay socket is available

#### Scenario: Reported session paths are host-valid

- **WHEN** the sandboxed Pi reports its session and the reported path is under `/root/.pi/agent`
- **THEN** herdr records the session path under the host Pi state directory instead

#### Scenario: Outside a herdr pane nothing changes

- **WHEN** `pi-box` runs without the herdr pane environment variables
- **THEN** no relay is started, no herdr environment variables are forwarded, and the sandbox behaves as before this change

### Requirement: Herdr restart resume stays inside the sandbox

When herdr restarts and types the Pi resume command into a restored pane shell that was running `pi-box`, the session SHALL resume inside the sandbox container, not in a host process.

#### Scenario: Restart resume routes through pi-box

- **WHEN** herdr restores a `pi-box` pane and types `pi --session <path under the host Pi state directory>` into the restored herdr-pane shell
- **THEN** the command runs `pi-box` with the same argument, starting a sandboxed session

#### Scenario: Session path is mapped into the container

- **WHEN** the resumed `pi` invocation inside the container receives the host session path argument
- **THEN** the argument points at the corresponding path under `/root/.pi/agent`, where the shared session file is mounted

#### Scenario: Host pi usage is unchanged outside herdr panes

- **WHEN** a user runs `pi` with any arguments in a shell that is not a herdr pane
- **THEN** the real host `pi` binary runs, exactly as before this change
