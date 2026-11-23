# Spec Delta

## REMOVED Requirements

### Requirement: Default-deny network with domain allowlist
The sandbox SHALL deny all outbound network access except connections to allowlisted domains: LLM API providers, GitHub and git hosting, and package registries. Connections to unlisted destinations SHALL fail closed.

#### Scenario: Provider requests succeed
- **WHEN** sandboxed Pi makes a provider request to an allowlisted LLM API domain
- **THEN** the request completes

#### Scenario: Unknown domain is blocked
- **WHEN** a process in the sandbox connects to a domain outside the allowlist
- **THEN** the connection is refused and the sandbox keeps running

#### Scenario: Localhost services require an opt-in port grant
- **WHEN** the sandboxed process connects to a host localhost port that the profile did not grant
- **THEN** the connection is refused

**Reason**: The shared base profile will inherit the registry Pi profile's default-allow network policy instead of imposing a host allowlist.

**Migration**: Projects that require restricted egress must opt in to a network block or filtering profile in their project profile.

## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Default-allow outbound network
The default sandbox SHALL inherit `nolabs-ai/pi`'s `network.block: false` policy without an active domain-filtering profile or static host allowlist, allowing outbound connections to arbitrary destinations.

#### Scenario: An unlisted public host is reachable
- **WHEN** a process in a default pi-box sandbox connects to `pi.dev` or another public host not named in pi-box configuration
- **THEN** the connection is permitted without a project-specific network grant

#### Scenario: A project can opt into restricted networking
- **WHEN** a project profile explicitly configures a network block or filtering profile
- **THEN** that project-specific network restriction applies to the run

### Requirement: Host OpenSpec CLI available by name
The default pi-box sandbox SHALL run the host-installed OpenSpec CLI from `~/.npm-global/bin/openspec` without requiring a project-specific filesystem grant, while keeping the CLI package read-only.

#### Scenario: OpenSpec command resolves in the sandbox
- **WHEN** `openspec --version` runs inside a default pi-box sandbox
- **THEN** it executes the host-installed CLI and reports its version

#### Scenario: OpenSpec package cannot be modified
- **WHEN** a process in the sandbox attempts to write to the OpenSpec package under `~/.npm-global/lib/node_modules/@fission-ai/openspec`
- **THEN** the write is denied
