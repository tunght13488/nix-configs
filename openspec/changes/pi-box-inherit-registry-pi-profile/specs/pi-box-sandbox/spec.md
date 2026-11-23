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
The default sandbox SHALL extend the installed `nolabs-ai/pi` profile and inherit its filesystem grants and runtime groups, including read-write access to `~/.pi`, `~/.cache`, and Nono profile drafts. It SHALL add pi-box host-integration grants and per-run workspace grants. The brokered GitHub token SHALL remain outside every path granted to the sandbox. `~/.aws`, `~/.ssh`, and the 1Password agent socket SHALL remain inaccessible.

#### Scenario: AWS credentials inaccessible
- **WHEN** a process in the sandbox opens a file under `~/.aws` (including the SSO token cache)
- **THEN** the open fails

#### Scenario: SSH identities inaccessible
- **WHEN** a process in the sandbox opens a file under `~/.ssh` or the 1Password agent socket
- **THEN** the open fails

#### Scenario: Effective grants include the registry Pi profile
- **WHEN** the default sandbox's effective grants are inspected
- **THEN** they include the installed `nolabs-ai/pi` profile grants, pi-box's host-integration grants, and the per-run workspace and worktree grants, including the registry's `~/.pi` and `~/.cache` read-write grants

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
- **THEN** no git directory is granted beyond the workspace and profile grants

### Requirement: GitHub authentication in the sandbox
GitHub authentication SHALL use nono credential injection with the real token stored at `~/.config/nono/credentials/pi-box-gh-token`, outside sandbox grants. The sandbox SHALL receive only the phantom `GH_TOKEN`; the real token SHALL NOT appear in its environment or profile. A legacy token at `~/.pi/sandbox/gh-token` SHALL prevent sandbox launch until it is moved or removed.

#### Scenario: gh can read pull requests
- **WHEN** `gh pr view` runs inside the sandbox with a configured token
- **THEN** it authenticates through the injected credential route and returns the pull request details

#### Scenario: Real token stays out of the sandbox
- **WHEN** the sandboxed process environment and profile are inspected
- **THEN** the real GitHub token appears in neither, and the new host-side token path is denied by the effective sandbox profile

#### Scenario: Missing token file leaves gh unauthenticated
- **WHEN** no token is configured at `~/.config/nono/credentials/pi-box-gh-token`
- **THEN** the sandbox still starts and `gh` reports an authentication failure instead of failing the run

#### Scenario: Legacy token blocks launch
- **WHEN** `~/.pi/sandbox/gh-token` still exists
- **THEN** `pi-box` exits before starting Nono and instructs the user to move the token to the new host-side path

### Requirement: Endpoint-restricted GitHub API access
Requests using the brokered GitHub credential SHALL be limited to the method and path patterns configured on the credential route. Requests that do not match those rules SHALL be rejected before the real token is injected. These endpoint rules SHALL NOT restrict general outbound network access.

#### Scenario: Reading pull requests is allowed
- **WHEN** `gh pr view` uses the brokered token route for a repository request matching its configured `GET /repos/**` rule
- **THEN** the request succeeds and returns the pull request details

#### Scenario: Disallowed credentialed endpoint is denied
- **WHEN** a process attempts a `DELETE` request to a GitHub API endpoint using the brokered token route
- **THEN** the proxy refuses the request before injecting the real token and records the denial

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
