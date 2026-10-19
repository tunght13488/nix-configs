# Spec Delta

## Purpose

Provides the `dig` DNS lookup tool in the user environment so interactive DNS queries work from the shell.

## ADDED Requirements

### Requirement: dig is available in the user environment
The home-manager configuration SHALL install a package providing the `dig` command, so `dig` is available on `PATH` for the `tung` user.

#### Scenario: dig resolves from PATH
- **WHEN** the user starts a new shell after home-manager activation
- **THEN** `command -v dig` SHALL print a path under `/nix/store`

#### Scenario: DNS lookup succeeds
- **WHEN** the user runs `dig +short example.com`
- **THEN** the command SHALL exit with status 0 and print at least one IP address

#### Scenario: myip alias works
- **WHEN** the user runs the existing `myip` zsh alias
- **THEN** the command SHALL exit with status 0 and print the machine's public IP address
