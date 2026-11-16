# Spec Delta

## MODIFIED Requirements

### Requirement: Least-privilege default grant set

By default the sandbox SHALL receive exactly these host resources: the project workspace (read-write), `~/.pi/agent` (read-write), `~/.config/git` (read-only), `~/.config/gh` (read-only), `~/.config/nvim` (read-only, when present), and — when the project is a git worktree or submodule whose git common directory lies outside the workspace — that git directory (read-write). The sandbox SHALL NOT receive `~/.aws`, `~/.ssh`, the 1Password agent socket, or any other host path.

#### Scenario: AWS credentials inaccessible
- **WHEN** a process in the sandbox reads `~/.aws` (including the SSO token cache)
- **THEN** the path does not exist inside the sandbox

#### Scenario: SSH identities inaccessible
- **WHEN** a process in the sandbox reads `~/.ssh` or the 1Password agent socket
- **THEN** the paths do not exist inside the sandbox

#### Scenario: Only granted paths are mounted
- **WHEN** the container's mounts are inspected on a default run
- **THEN** the host-backed mounts are exactly the workspace, `~/.pi/agent`, `~/.config/git`, `~/.config/gh`, `~/.config/nvim` when it exists, plus the project's git directory when it lives outside the workspace

#### Scenario: Neovim configuration is available read-only
- **WHEN** the host's `~/.config/nvim` exists and a default sandbox run starts
- **THEN** its configuration is available at `/root/.config/nvim` and writes through the mount are denied

#### Scenario: Missing Neovim configuration does not prevent launch
- **WHEN** the host's `~/.config/nvim` does not exist
- **THEN** the sandbox still starts without that mount

#### Scenario: Git metadata outside the workspace is usable
- **WHEN** the project is a worktree in a bare-repository layout and `git status`, `git log`, or a commit runs inside the sandbox
- **THEN** the command succeeds against the same repository as on the host

#### Scenario: Plain project adds no extra mount
- **WHEN** the project's `.git` is a directory inside the workspace
- **THEN** no git directory is mounted beyond the workspace

## ADDED Requirements

### Requirement: Neovim in the shared base image

The shared `pi-sandbox` image SHALL provide the official Neovim v0.12.6 release (the latest stable release at this plan update), and project images derived from it SHALL inherit that version without project-specific installation.

#### Scenario: Base image provides the pinned release
- **WHEN** `nvim --version` runs in a sandbox using the base image
- **THEN** it reports Neovim v0.12.6

#### Scenario: Project images inherit Neovim
- **WHEN** `nvim --version` runs in a project image derived from `pi-sandbox`
- **THEN** it reports Neovim v0.12.6 without project-specific installation

### Requirement: Nixvim plugins are available in the shared image

The shared image SHALL provide the plugin runtime required by the mounted host Nixvim configuration, including TokyoNight, without requiring host Nix-store plugin/runtime mounts.

#### Scenario: Host Nixvim configuration loads
- **WHEN** Neovim starts with the mounted host configuration in a default sandbox
- **THEN** the configured plugins, including TokyoNight, resolve and initialization reports no missing plugin-module errors

#### Scenario: Plugin runtime does not add host grants
- **WHEN** the default sandbox mounts are inspected
- **THEN** plugin runtime files are provided by the image and no host Nix-store plugin/runtime path is mounted

### Requirement: Neovim is Pi's default external editor

The shared `pi-sandbox` image SHALL configure `nvim` as Pi's external-editor fallback so Ctrl+G launches Neovim when no explicit Pi `externalEditor` setting is configured.

#### Scenario: Ctrl+G opens Neovim by default
- **WHEN** Pi runs in a sandbox without an explicit `externalEditor` setting and the user invokes Ctrl+G
- **THEN** the prompt opens in Neovim and returns to Pi after the editor exits successfully

#### Scenario: Explicit editor setting is preserved
- **WHEN** Pi has an explicit `externalEditor` setting
- **THEN** Pi uses that configured command instead of the `EDITOR` fallback
