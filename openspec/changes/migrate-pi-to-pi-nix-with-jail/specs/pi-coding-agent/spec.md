# Spec Delta

## Purpose

Runs the pi coding agent as a flake-provided tool inside a bubblewrap jail that exposes the checked-out code and a test/lint/build environment while denying the user's credential surfaces.

## ADDED Requirements

### Requirement: Pi binary provided by the pi.nix flake input
The user environment SHALL provide the `pi` coding agent binary built from the `lukasl-dev/pi.nix` flake input via the Home Manager `programs.pi.coding-agent` module.

#### Scenario: pi resolves to the Home Manager profile
- **WHEN** a fresh shell runs `command -v pi`
- **THEN** it resolves to the Home Manager profile path, not `~/.pi/agent/bin/pi` or `~/.local/bin/pi`

#### Scenario: pi version matches the packaged input
- **WHEN** a user runs `pi --version`
- **THEN** it prints the version packaged by the current `pi.nix` flake input (1.2.0 at migration time)

#### Scenario: pi update does not self-install
- **WHEN** a user runs `pi update` with the flake-provided binary
- **THEN** no new release is installed under `~/.pi/agent/install`; version changes come from updating the flake input

### Requirement: Agent directory state preserved
The user environment SHALL keep all existing agent-directory state in `~/.pi/agent` working unchanged after the migration: settings, credentials, sessions, npm-installed extensions, skills, and extension files.

#### Scenario: npm extensions resolve from the agent directory
- **WHEN** the flake-provided pi starts
- **THEN** the `npm:` packages listed in `settings.json` (pi-web-access, pi-powerline-footer, @plannotator/pi-extension) load from `~/.pi/agent/npm`

#### Scenario: settings and credentials are untouched
- **WHEN** the migration is complete
- **THEN** `~/.pi/agent/settings.json`, `auth.json`, `trust.json`, and `sessions/` are unchanged from before the migration

#### Scenario: Rules and skill files keep their mechanisms
- **WHEN** Home Manager activates
- **THEN** `~/.pi/agent/AGENTS.md` and `~/.pi/agent/skills/herdr/SKILL.md` remain managed by their existing home-manager files, not by pi module options

### Requirement: Self-managed install retired
The user environment SHALL remove the pi self-managed install (launcher script, entrypoint symlink, and `~/.pi/agent/install`) once the flake-provided binary is verified, while the agent directory continues to function.

#### Scenario: launcher and entrypoint absent
- **WHEN** the cutover is complete
- **THEN** `~/.local/bin/pi` and `~/.pi/agent/bin/pi` no longer exist and `command -v pi` resolves to the Home Manager profile

#### Scenario: install directory removed
- **WHEN** the flake-provided pi is verified and no live session uses the old release
- **THEN** `~/.pi/agent/install` is deleted and pi still starts and loads extensions normally

### Requirement: Jail provides the working code environment
The jailed agent environment SHALL mount the runtime working directory and the pi agent directory read-write, so code edits, commits, and agent state writes succeed.

#### Scenario: working directory is writable
- **WHEN** the agent edits files and creates git commits in the repository it was started in
- **THEN** writes and commits succeed

#### Scenario: agent directory is writable
- **WHEN** pi writes sessions, trust state, or extension package updates under `~/.pi/agent`
- **THEN** the writes persist across invocations

#### Scenario: project worktree repos usable
- **WHEN** the agent creates commits in the `netsuite-middleware/middleware_alpha`, `fc-es-starter-pack/oms_backend_main`, or `fc-omx/oms_frontend_main` worktrees
- **THEN** git operations succeed via each repo's `.bare` while sibling worktrees remain read-only

### Requirement: Jail provides network access
The jailed agent environment SHALL have network access for model provider APIs and extension package downloads.

#### Scenario: model APIs reachable
- **WHEN** pi runs jailed and sends a request to the configured provider
- **THEN** the request succeeds over the network

### Requirement: Credential surfaces denied in jail
The jailed agent environment SHALL NOT expose the user's credential surfaces: `~/.aws`, `~/.ssh`, the 1Password agent socket, `~/.npmrc`, the token-bearing `~/.config/nix/nix.conf`, and the herdr client socket.

#### Scenario: home credential paths absent
- **WHEN** the agent accesses `~/.aws`, `~/.ssh`, `~/.1password/agent.sock`, or `~/.npmrc` inside the jail
- **THEN** the paths are not present or not accessible

#### Scenario: token-bearing nix config absent
- **WHEN** the agent reads `~/.config/nix/nix.conf` inside the jail
- **THEN** the file (including its `access-tokens` line) is not present; only the token-free system `/etc/nix/nix.conf` is used

#### Scenario: herdr socket unreachable
- **WHEN** the agent attempts to connect to the herdr client socket inside the jail
- **THEN** the connection fails; no herdr control is possible

### Requirement: Nix evaluation and builds inside the jail
The jailed agent environment SHALL provide read-only access to `/nix/store`, the nix daemon socket, and the nix client, so repository evaluation and build targets run without leaving the jail.

#### Scenario: home build succeeds jailed
- **WHEN** the agent runs `make home-build` inside the jail
- **THEN** the Home Manager configuration evaluates and builds successfully

#### Scenario: os build succeeds jailed
- **WHEN** the agent runs `make os-build` inside the jail
- **THEN** the NixOS configuration evaluates and builds successfully

### Requirement: Project toolchains available inside the jail
The jailed agent environment SHALL provide the toolchains the agent's projects require — PHP with versioned binaries and Composer, Java with Maven, Node.js with Yarn — alongside persistent language dependency caches.

#### Scenario: PHP toolchain works jailed
- **WHEN** the agent runs the `php81`/`php82`/`php83` binaries or the versioned Composer commands required by the project's `composer.json` inside the jail in `netsuite-middleware/middleware_alpha`
- **THEN** the commands succeed and project test runs work

#### Scenario: Java toolchain works jailed
- **WHEN** the agent runs `java -version` (1.8) and `mvn -version` (3.6.3) inside the jail in `fc-es-starter-pack/oms_backend_main`
- **THEN** the commands succeed and Maven resolves dependencies from the persistent `~/.m2` cache

#### Scenario: Node toolchain works jailed
- **WHEN** the agent runs `node --version` (22.x) and `yarn --version` inside the jail in `fc-omx/oms_frontend_main`
- **THEN** the commands succeed and dependency installs use the persistent npm and Yarn caches

#### Scenario: dependency caches persist across sessions
- **WHEN** a second jailed session runs the same Maven, Composer, npm, or Yarn dependency resolution
- **THEN** dependencies resolve from the persistent caches without full re-downloads

### Requirement: gh available inside the jail
The jailed agent environment SHALL provide a working, authenticated `gh` CLI and git push over https, without SSH access.

#### Scenario: gh commands work jailed
- **WHEN** the agent runs `gh` commands that read or create pull requests
- **THEN** they authenticate and succeed using the existing gh configuration

#### Scenario: push goes over https
- **WHEN** the agent runs `git push` inside the jail
- **THEN** the `git@github.me:` remote is rewritten to `https://github.com/` and the push authenticates via the gh credential helper, without SSH

### Requirement: openspec CLI available inside the jail
The jailed agent environment SHALL provide the `openspec` CLI without exposing `~/.npmrc`.

#### Scenario: openspec commands work jailed
- **WHEN** the agent runs `openspec list` or `openspec status` inside the jail
- **THEN** the commands succeed and `~/.npmrc` is not accessible

### Requirement: herdr state visibility without socket access
pi running in a herdr pane inside the jail SHALL be identified to herdr via the host-visible `HERDR_AGENT=pi` environment hint, so herdr reports pi state from screen detection, without any herdr socket access from the jail.

#### Scenario: herdr identifies the jailed pi
- **WHEN** the flake-provided jailed pi runs as the foreground process of a herdr pane
- **THEN** herdr treats that process as the pi agent via the `HERDR_AGENT=pi` hint on the wrapper

#### Scenario: state transitions reported
- **WHEN** the jailed pi is generating, idle, or showing an approval prompt
- **THEN** herdr reports working, idle, or blocked respectively, or its manifest-known idle fallback for unrecognized prompt shapes

#### Scenario: socket extension inert
- **WHEN** the jailed pi starts
- **THEN** no `HERDR_SOCKET_PATH`, `HERDR_ENV`, or `HERDR_PANE_ID` variables are forwarded and the socket extension makes no connection attempts

### Requirement: pi binary cache configured
The system nix settings SHALL include the pi.cachix.org binary cache so the pi package and its dependencies substitute instead of building from source.

#### Scenario: pi package substitutes
- **WHEN** nix builds the pi coding-agent package
- **THEN** it is fetched from `pi.cachix.org` rather than built locally
