# pi-box-sandbox Specification

## Purpose

Runs the Pi coding agent per project inside a nono capability sandbox with least-privilege host access: a deployed shared base profile that inherits the registry Pi profile, per-project opt-in grants that extend it, shared Pi identity and state, default-allow outbound networking, brokered GitHub credentials, and never-granted host secrets such as AWS, SSH and the 1Password socket.

## Requirements

### Requirement: Per-project sandboxed Pi session

Running `pi-box` in a project directory SHALL start an interactive Pi session under a nono capability sandbox with that directory granted read-write as the working directory. The session SHALL run as a host process under the invoking user.

#### Scenario: Launch from project root
- **WHEN** `pi-box` is run inside a project directory
- **THEN** Pi's TUI starts in the project directory under the sandbox, running as the invoking host user

#### Scenario: Workspace writes reach the host
- **WHEN** sandboxed Pi creates or edits a file in the workspace
- **THEN** the change is immediately visible at the same path on the host

#### Scenario: Container files owned by the host user
- **WHEN** a process inside the sandbox creates a file in the workspace
- **THEN** the file is owned by the invoking host user

### Requirement: Least-privilege default grant set

The default sandbox SHALL inherit the installed `nolabs-ai/pi` profile's filesystem grants and runtime groups — including `~/.pi` and `~/.cache` read-write — and add pi-box's own grants: the workspace (read-write), `/tmp` as `TMPDIR`, host config read-only, Neovim state, the OpenSpec CLI read-only, `/nix`, and the sandbox runtime directory. The brokered GitHub token SHALL stay outside every granted path. `~/.aws`, `~/.ssh`, and the 1Password agent socket SHALL stay inaccessible.

#### Scenario: AWS credentials inaccessible
- **WHEN** a process in the sandbox opens a file under `~/.aws` (including the SSO token cache)
- **THEN** the open fails

#### Scenario: SSH identities inaccessible
- **WHEN** a process in the sandbox opens a file under `~/.ssh` or the 1Password agent socket
- **THEN** the open fails

#### Scenario: Only granted paths are mounted
- **WHEN** the session's effective grants are inspected on a default run
- **THEN** the granted host paths are the inherited registry profile grants (`~/.pi`, Nono profile drafts, `~/.cache`, the runtime and system-read groups), pi-box's additions (the workspace, `/tmp`, `~/.config/git`, `~/.config/gh`, `~/.config/nvim` when it exists, `~/.local/state/nvim`, `~/.local/share/nvim`, `~/.config/github-copilot`, `/nix`, `~/.pi/sandbox/runtime`, `~/.npm-global/bin`, and the OpenSpec package), plus the project's git directory and the repository root `AGENTS.md` when the git directory lives outside the workspace

#### Scenario: Standard temporary directory is used
- **WHEN** Pi starts inside the sandbox
- **THEN** `TMPDIR` is `/tmp` and is writable

#### Scenario: Neovim configuration is available read-only
- **WHEN** the host's `~/.config/nvim` exists and a default sandbox run starts
- **THEN** its configuration is readable and write attempts to it are denied

#### Scenario: Missing Neovim configuration does not prevent launch
- **WHEN** the host's `~/.config/nvim` does not exist
- **THEN** the sandbox still starts without that grant

#### Scenario: Git metadata outside the workspace is usable
- **WHEN** the project is a worktree in a bare-repository layout and `git status`, `git log`, or a commit runs inside the sandbox
- **THEN** the command succeeds against the same repository as on the host

#### Scenario: Repository root instructions readable
- **WHEN** the project is a worktree in a bare-repository layout and Pi reads the repository root `AGENTS.md`
- **THEN** the file content is accessible read-only

#### Scenario: Plain project adds no extra mount
- **WHEN** the project's `.git` is a directory inside the workspace
- **THEN** no git directory is granted beyond the workspace and the profile grants

#### Scenario: Effective grants include the registry Pi profile
- **WHEN** the default sandbox's effective grants are inspected
- **THEN** they include the registry's `~/.pi` and `~/.cache` read-write grants alongside pi-box's own grants

### Requirement: Shared Pi identity, state, and instructions

The sandbox SHALL use the host's `~/.pi/agent` read-write as its Pi state: provider credentials from `auth.json`, settings, sessions, skills, and trust decisions are shared with host Pi. No provider credential SHALL be passed to the sandboxed process through environment variables. The global `~/.pi/agent/AGENTS.md` SHALL be readable inside the sandbox.

#### Scenario: No credential environment variables
- **WHEN** the sandboxed process environment is inspected
- **THEN** it contains no provider API key or OAuth token variables

#### Scenario: Model access without per-sandbox login
- **WHEN** sandboxed Pi makes a provider request using a provider already authenticated on the host
- **THEN** the request authenticates via the shared `auth.json` without any login step in the sandbox

#### Scenario: State changes propagate to the host
- **WHEN** sandboxed Pi records a session, setting, or trust decision
- **THEN** the same state is visible to host Pi on its next run

#### Scenario: Global instructions readable
- **WHEN** sandboxed Pi reads its global `AGENTS.md`
- **THEN** the content matches the host's global Pi instructions

### Requirement: Git and GitHub identity in the sandbox

The sandbox SHALL carry the host's git and GitHub configuration via read-only grants of `~/.config/git` and `~/.config/gh`, used as-is by the host-native session.

#### Scenario: Commits carry host identity
- **WHEN** a commit is created inside the sandbox
- **THEN** the author name and email match the host git configuration

#### Scenario: Git over HTTPS uses the in-container credential helper
- **WHEN** git authenticates against `https://github.com` inside the sandbox
- **THEN** it uses the host credential helper and authenticates successfully

#### Scenario: Host-only tools are not invoked
- **WHEN** git requires an editor or credential prompt inside the sandbox
- **THEN** the host-configured editor runs

### Requirement: GitHub authentication in the sandbox
GitHub authentication SHALL use nono credential injection with the real token stored at `~/.config/nono/credentials/pi-box-gh-token`, outside sandbox grants. The sandbox SHALL receive only the phantom `GH_TOKEN`. A legacy token at `~/.pi/sandbox/gh-token` SHALL prevent sandbox launch until it is moved or removed.

#### Scenario: gh can read pull requests
- **WHEN** `gh pr view` runs inside the sandbox with a configured token
- **THEN** it authenticates with the injected credential and returns the pull request details

#### Scenario: Token stays out of the container environment
- **WHEN** the sandboxed process environment and the profile are inspected
- **THEN** the GitHub token appears in neither, and the host-side token path is denied by the effective sandbox profile

#### Scenario: Missing token file leaves gh unauthenticated
- **WHEN** no token is configured
- **THEN** the sandbox still starts and `gh` reports an authentication failure instead of failing the run

#### Scenario: Legacy token blocks launch
- **WHEN** `~/.pi/sandbox/gh-token` still exists
- **THEN** `pi-box` exits before starting Nono and instructs the user to move the token to the new host-side path

### Requirement: Per-project opt-in grants via manifest

A per-project nono profile (`pi-box.profile.json`) SHALL be the only mechanism for granting resources beyond the default set. The profile SHALL extend the deployed pi-box base profile by name, and nono SHALL merge every field of its profile schema; fields outside the schema SHALL fail the run with a validation error. Grants not declared in the profile or the base SHALL NOT be present.

#### Scenario: Host database access
- **WHEN** the profile sets `network.connect_port` to the MySQL port and the sandbox runs the project's feature tests
- **THEN** the tests connect to the host's MySQL without database credentials duplicated in the profile

#### Scenario: Dropping the GitHub identity
- **WHEN** the sandbox has no GitHub token file
- **THEN** `gh` commands are unauthenticated and the read-only `~/.config/gh` grant carries no credentials

#### Scenario: Undeclared grants are absent
- **WHEN** the profile declares no ports, env vars, or extra paths
- **THEN** the sandbox grants no ports, carries no extra environment variables, and exposes no extra paths

#### Scenario: Extra read-write path persists across runs
- **WHEN** the profile grants a read-write path such as `~/.m2` via `filesystem.allow` and a run writes files there
- **THEN** a later run of the same project finds those files

#### Scenario: Named volume persists across runs
- **WHEN** the profile sets a field outside the nono profile schema, such as `volumes`
- **THEN** the run fails with a profile validation error instead of silently ignoring the field

#### Scenario: Privileged mode is opt-in
- **WHEN** the profile requests namespace isolation via `linux.isolate` on a host that cannot create the namespaces
- **THEN** nono fails at startup rather than running with a degraded boundary

### Requirement: Project scaffold creation

`pi-box init [--force] [template]` SHALL create the per-project profile (`pi-box.profile.json`) in the current project directory from the named template, or from the default template when no name is given. Existing files SHALL be backed up with a shared timestamp before being overwritten, and only when the user confirms interactively or `--force` is passed; otherwise they SHALL be left untouched. The profile SHALL be ignored by the user's global gitignore so it remains untracked in every repository.

#### Scenario: Scaffold a new worktree
- **WHEN** `pi-box init` runs in a project without the scaffold files
- **THEN** `pi-box.profile.json` is created from the default template

#### Scenario: Scaffold with a named template
- **WHEN** `pi-box init php83` runs in a project without the scaffold files
- **THEN** `pi-box.profile.json` matches the php83 template

#### Scenario: Templates are listable
- **WHEN** `pi-box init --list` runs
- **THEN** the available template names are printed

#### Scenario: Unknown template fails with the list
- **WHEN** `pi-box init nosuchtemplate` runs
- **THEN** init exits non-zero without writing anything and prints the available template names

#### Scenario: Interactive overwrite backs up first
- **WHEN** `pi-box init` runs in a project with an existing scaffold file and the user answers yes to the single prompt
- **THEN** the existing file is copied to `pi-box.profile.json.<YYYYmmdd-HHMMSS>.bak` and the new file is written

#### Scenario: Idempotent scaffold
- **WHEN** `pi-box init` runs in a project that already has the scaffold file and the user answers no
- **THEN** the existing file is not modified

#### Scenario: Non-interactive init never overwrites
- **WHEN** `pi-box init` runs without a terminal in a project with an existing scaffold file
- **THEN** the existing file is not modified

#### Scenario: Force overwrites without prompting
- **WHEN** `pi-box init --force php83` runs in a project with an existing scaffold file
- **THEN** the existing file is backed up with a timestamp and the template file is written without any prompt

#### Scenario: Scaffolds stay untracked
- **WHEN** `git status` runs in any repository containing `pi-box.profile.json`
- **THEN** the file does not appear as untracked

### Requirement: GitHub SCP-style SSH remotes work without SSH credentials

Git operations in the sandbox that target GitHub using SCP-style SSH URLs SHALL transparently use HTTPS and the host GitHub credential helper. This SHALL NOT require granting SSH identities or changing the repository's configured remote URL.

#### Scenario: Fetch through a GitHub SSH-form remote
- **WHEN** `git fetch`, `git ls-remote`, or a clone targets `git@github.com:ORG/REPO.git` and the sandbox has a valid GitHub credential
- **THEN** the operation succeeds over HTTPS using the host credential helper without an SSH agent

#### Scenario: Existing remote configuration remains unchanged
- **WHEN** a Git operation uses an SSH-form GitHub remote in the sandbox
- **THEN** the configured remote URL remains `git@github.com:ORG/REPO.git`

#### Scenario: Other SSH hosts are not rewritten
- **WHEN** a Git operation targets an SSH URL for a host other than `github.com`
- **THEN** the sandbox does not rewrite that URL as a GitHub HTTPS URL

### Requirement: Herdr restart resume stays inside the sandbox

When herdr restarts and types the Pi resume command into a restored pane shell that was running `pi-box`, the session SHALL resume inside the sandbox, not in an unsandboxed host process.

#### Scenario: Restart resume routes through pi-box

- **WHEN** herdr restores a `pi-box` pane and types `pi --session <path under the host Pi state directory>` into the restored herdr-pane shell
- **THEN** the command runs `pi-box` with the same argument, starting a sandboxed session

#### Scenario: Session path is mapped into the container

- **WHEN** the resumed sandboxed Pi receives the host session path argument
- **THEN** the argument points at the host Pi state directory and the session resumes

#### Scenario: Host pi usage is unchanged outside herdr panes

- **WHEN** a user runs `pi` with any arguments in a shell that is not a herdr pane
- **THEN** the real host `pi` binary runs, exactly as before this change

### Requirement: Neovim is Pi's default external editor

The sandbox SHALL configure `nvim` as Pi's external-editor fallback so Ctrl+G launches Neovim when no explicit Pi `externalEditor` setting is configured.

#### Scenario: Ctrl+G opens Neovim by default
- **WHEN** Pi runs in a sandbox without an explicit `externalEditor` setting and the user invokes Ctrl+G
- **THEN** the prompt opens in the host Neovim and returns to Pi after the editor exits successfully

#### Scenario: Explicit editor setting is preserved
- **WHEN** Pi has an explicit `externalEditor` setting
- **THEN** Pi uses that configured command instead of the `EDITOR` fallback

### Requirement: Default-allow outbound network
The default sandbox SHALL inherit `nolabs-ai/pi`'s `network.block: false` policy without an active domain-filtering profile or static host allowlist, allowing outbound connections to arbitrary destinations.

#### Scenario: An unlisted public host is reachable
- **WHEN** a process in a default pi-box sandbox connects to `pi.dev` or another public host not named in pi-box configuration
- **THEN** the connection is permitted without a project-specific network grant

#### Scenario: A project can opt into restricted networking
- **WHEN** a project profile explicitly configures a network block or filtering profile
- **THEN** that project-specific network restriction applies to the run

### Requirement: Endpoint-restricted GitHub API access
Requests using the brokered GitHub credential SHALL be limited to the method and path patterns configured on the credential route; non-matching requests SHALL be rejected before the real token is injected. These rules SHALL NOT restrict general outbound traffic.

#### Scenario: Reading pull requests is allowed
- **WHEN** `gh pr view` runs inside the sandbox against a repository the profile allows
- **THEN** the request succeeds and returns the pull request details

#### Scenario: Destructive endpoints are denied
- **WHEN** a process in the sandbox calls a destructive GitHub API endpoint such as repository deletion
- **THEN** the request is refused before the real token is injected and recorded in the audit log

#### Scenario: The configured GraphQL rule remains a known limitation
- **WHEN** a brokered-token request uses `POST /graphql`
- **THEN** it matches the configured route rule and may be forwarded, because method and path rules cannot distinguish a GraphQL query from a mutation

### Requirement: Sandbox operations are audited
Blocked network requests and denied operations SHALL be recorded in a tamper-evident audit log that remains readable on the host after the session ends.

#### Scenario: Blocked request is recorded
- **WHEN** a sandboxed process attempts a blocked outbound connection
- **THEN** the attempt appears in the session's audit record

#### Scenario: Audit record survives the session
- **WHEN** the sandbox session has ended
- **THEN** the audit record is readable on the host

### Requirement: Privilege escalation and destructive commands are blocked
The sandbox SHALL refuse privilege-escalation and destructive commands, including indirect invocation through shell chains, before they execute.

#### Scenario: Privilege escalation is refused
- **WHEN** a process in the sandbox attempts to run `sudo`
- **THEN** the command is refused and the sandbox keeps running

#### Scenario: Blocking survives shell chains
- **WHEN** a sandboxed shell runs a chained command such as `false && sudo id`
- **THEN** the privileged command is still refused

### Requirement: Herdr agent state reporting

When `pi-box` runs inside a herdr pane, the sandbox SHALL report Pi's working, blocked, and idle states to herdr directly through the herdr socket, as host Pi does. No relay process SHALL be started.

#### Scenario: Sandboxed pane reports real agent states

- **WHEN** `pi-box` is started in a herdr pane and the sandboxed Pi session begins, works, and blocks on user input
- **THEN** the herdr agent sidebar shows working, blocked, and idle at the matching moments, as it does for a host Pi pane

#### Scenario: No relay process runs

- **WHEN** a sandbox run inside a herdr pane is inspected
- **THEN** no relay process exists; the sandboxed session connects to the herdr socket directly

#### Scenario: Outside a herdr pane nothing changes

- **WHEN** `pi-box` runs without the herdr pane environment variables
- **THEN** no herdr connection is attempted and the sandbox behaves as a plain run

### Requirement: Sandboxed Pi uses the home-manager Pi release

The sandbox SHALL run the Pi release installed by home-manager (currently 1.5.2), with no separately pinned image copy.

#### Scenario: Sandbox runs the home-manager release
- **WHEN** `pi --version` runs in a sandbox after the home-manager Pi package is updated
- **THEN** the sandbox reports the same version as host Pi

### Requirement: Deployed shared base profile
Home Manager SHALL deploy `~/.config/nono/profiles/pi-box.json` as a child of the installed `nolabs-ai/pi` profile, adding pi-box's host-specific grants and environment deny-list while inheriting the registry profile's network and filesystem policy. Project profiles and the wrapper's per-run overlay SHALL compose with it through nono's profile inheritance.

#### Scenario: Base profile is deployed and valid
- **WHEN** Home Manager has been applied and `nolabs-ai/pi` is installed
- **THEN** `~/.config/nono/profiles/pi-box.json` extends `nolabs-ai/pi` and passes `nono profile validate`

#### Scenario: Registry network policy remains effective
- **WHEN** the resolved pi-box base profile is inspected
- **THEN** it has default-allow outbound networking with no pi-box domain-filtering profile or static host allowlist

#### Scenario: Overlay composes with the base
- **WHEN** `pi-box` runs and the effective grants are inspected
- **THEN** the registry profile grants, pi-box base grants, project profile grants, and per-run overlay grants are all present

### Requirement: Host OpenSpec CLI available by name
The default pi-box sandbox SHALL run the host-installed OpenSpec CLI from `~/.npm-global/bin/openspec` without requiring a project-specific filesystem grant, while keeping the CLI package read-only.

#### Scenario: OpenSpec command resolves in the sandbox
- **WHEN** `openspec --version` runs inside a default pi-box sandbox
- **THEN** it executes the host-installed CLI and reports its version

#### Scenario: OpenSpec package cannot be modified
- **WHEN** a process in the sandbox attempts to write to the OpenSpec package under `~/.npm-global/lib/node_modules/@fission-ai/openspec`
- **THEN** the write is denied
