# Proposal

## Why

The zsh `myip` alias (`home-manager/zsh.nix`) invokes `dig`, but `dig` is not installed anywhere in the NixOS or home-manager configuration, so the alias fails with "command not found". Installing `dig` makes the alias work and provides a standard DNS troubleshooting tool.

## What Changes

- Install `dnsutils` (provides `dig`, `host`, `nslookup`) as a home-manager user package for `tung`.
- No changes to existing aliases or system-level configuration.

## Capabilities

### New Capabilities

- `dns-tools`: Availability of the `dig` DNS lookup tool in the user environment, so interactive DNS queries work from the shell.

### Modified Capabilities

<!-- None: the zsh-shell-aliases requirements are unchanged; the `myip` alias already exists and is unaffected by this change. -->

## Impact

- `home-manager/terminal.nix` (or `home.nix`): add `dnsutils` to `home.packages`.
- Requires `make home-build` verification and a `home-manager switch` by the user to take effect.
- No system-level, alias, or spec changes beyond the new capability.
