## Purpose

Defines which interactive zsh aliases shadow standard commands with modern replacements, as configured in `home-manager/zsh.nix` via `programs.zsh.shellAliases`.

## Requirements

### Requirement: Standard command aliases are disabled

The shell configuration SHALL NOT alias `find`, `grep`, or `ls` to replacement tools (`fd`, `rg`, `eza`). These aliases SHALL be commented out in `home-manager/zsh.nix` rather than deleted, so they can be re-enabled later.

#### Scenario: Interactive shell uses real find

- **WHEN** a user runs `find` in an interactive zsh session after applying the configuration
- **THEN** the system `find` binary executes, not `fd`

#### Scenario: Interactive shell uses real grep

- **WHEN** a user runs `grep` in an interactive zsh session after applying the configuration
- **THEN** the system `grep` binary executes, not `rg`

#### Scenario: Interactive shell uses real ls

- **WHEN** a user runs `ls` in an interactive zsh session after applying the configuration
- **THEN** the system `ls` binary executes, not `eza`

#### Scenario: Aliases preserved as comments

- **WHEN** a reader inspects `programs.zsh.shellAliases` in `home-manager/zsh.nix`
- **THEN** the `find`, `grep`, and `ls` alias entries are present but commented out

### Requirement: Remaining aliases stay active

The shell configuration SHALL keep the `cat` alias mapped to `bat --paging=never --style=plain` and the `du` alias mapped to `ncdu`, along with all other existing aliases not named `find`, `grep`, or `ls`.

#### Scenario: cat alias still active

- **WHEN** a user runs `cat` in an interactive zsh session after applying the configuration
- **THEN** `bat --paging=never --style=plain` executes

### Requirement: Dependent aliases fall back to system ls

The `l` (`ls -l`) and `la` (`l -a`) aliases SHALL remain defined. With `ls` no longer aliased, they SHALL resolve to the system `ls` binary.

#### Scenario: l alias falls back to system ls

- **WHEN** a user runs `l` in an interactive zsh session after applying the configuration
- **THEN** the system `ls -l` executes, not `eza`

### Requirement: Documentation reflects active aliases

The `AGENTS.md` "Shell Aliases" table SHALL list only aliases that are active, so `find`, `grep`, and `ls` rows SHALL be removed while `cat` and `du` rows remain.

#### Scenario: AGENTS.md table matches configuration

- **WHEN** a reader compares the `AGENTS.md` Shell Aliases table with `programs.zsh.shellAliases`
- **THEN** every row in the table corresponds to an active (non-commented) alias