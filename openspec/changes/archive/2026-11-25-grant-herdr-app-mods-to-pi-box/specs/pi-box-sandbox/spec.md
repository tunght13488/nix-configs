# Spec Delta

## MODIFIED Requirements

### Requirement: Least-privilege default grant set

The default sandbox SHALL inherit the installed `nolabs-ai/pi` profile's filesystem grants and runtime groups — including `~/.pi` and `~/.cache` read-write — and add pi-box's own grants: the workspace (read-write), `/tmp` as `TMPDIR`, host config read-only, `~/.config/herdr-app/mods` read-write, Neovim state, the OpenSpec CLI read-only, `/nix`, and the sandbox runtime directory. The brokered GitHub token SHALL stay outside every granted path. `~/.aws`, `~/.ssh`, and the 1Password agent socket SHALL stay inaccessible.

#### Scenario: AWS credentials inaccessible
- **WHEN** a process in the sandbox opens a file under `~/.aws` (including the SSO token cache)
- **THEN** the open fails

#### Scenario: SSH identities inaccessible
- **WHEN** a process in the sandbox opens a file under `~/.ssh` or the 1Password agent socket
- **THEN** the open fails

#### Scenario: Only granted paths are mounted
- **WHEN** the session's effective grants are inspected on a default run
- **THEN** the granted host paths are the inherited registry profile grants (`~/.pi`, Nono profile drafts, `~/.cache`, the runtime and system-read groups), pi-box's additions (the workspace, `/tmp`, `~/.config/git`, `~/.config/gh`, `~/.config/nvim` when it exists, `~/.local/state/nvim`, `~/.local/share/nvim`, `~/.config/github-copilot`, `~/.config/herdr-app/mods` read-write, `/nix`, `~/.pi/sandbox/runtime`, `~/.npm-global/bin`, and the OpenSpec package), plus the project's git directory and the repository root `AGENTS.md` when the git directory lives outside the workspace

#### Scenario: Herdr mods directory is read-write
- **WHEN** a process in a default pi-box sandbox reads a mod or creates or updates a file under `~/.config/herdr-app/mods`
- **THEN** the operation succeeds and changes are visible at the same host path

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
