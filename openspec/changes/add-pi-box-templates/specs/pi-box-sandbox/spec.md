# Spec Delta

## MODIFIED Requirements

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
