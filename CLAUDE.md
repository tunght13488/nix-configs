# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Approach

- Think before acting. Read existing files before writing code.
- Be concise in output but thorough in reasoning.
- Prefer editing over rewriting whole files.
- Do not re-read files you have already read unless the file may have changed.
- Test your code before declaring done.
- No sycophantic openers or closing fluff.
- Keep solutions simple and direct.
- User instructions always override this file.

## Commands

```bash
# Validate without changing flake.lock
nix flake show --no-write-lock-file

# Apply system changes
sudo nixos-rebuild switch --flake ".#nixos-vmware"

# Apply user-only changes
home-manager switch --flake ".#tung@nixos-vmware"

# Format Nix files
nixfmt <file>
```

## Testing Changes

Always verify configuration changes by running the appropriate switch command:
- Run `home-manager switch --flake ".#tung@nixos-vmware"` after modifying home-manager modules
- Run `sudo nixos-rebuild switch --flake ".#nixos-vmware"` after modifying system configuration
- Check command output for errors before considering the task complete

## Looking Up Home Manager Options

Do NOT hallucinate home-manager options. Always verify options exist before using them:

1. **Check module source code** (preferred - avoids large file downloads):
   - URL pattern: `https://github.com/nix-community/home-manager/blob/master/modules/programs/<program-name>.nix`
   - Example: `https://github.com/nix-community/home-manager/blob/master/modules/programs/claude-code.nix`
   - Look for `mkOption` and `mkEnableOption` definitions

2. **Search options documentation** (large file - use targeted search):
   - URL: `https://nix-community.github.io/home-manager/options.xhtml`
   - Never read entire content - use WebFetch with specific query about the program name

## Shell Environment

Default shell is **zsh** with Prezto. The following aliases replace standard commands:

| Alias | Actual Command |
|-------|----------------|
| `cat` | `bat --paging=never --style=plain` |
| `find` | `fd` |
| `grep` | `rg` (ripgrep) |
| `ls` | `eza --group-directories-first` |
| `du` | `ncdu` |

When running shell commands, be aware these replacements affect syntax and flags.

## Architecture

Flake-based NixOS configuration for `nixos-vmware` with separate system and user layers.

**flake.nix** pins `nixpkgs`, `home-manager`, and `nixvim` to 25.11 releases. Exposes:
- `nixosConfigurations.nixos-vmware` - system config
- `homeConfigurations."tung@nixos-vmware"` - user config

**nixos/configuration.nix** owns: Nix settings, hostname/timezone, GNOME on X11, VMware guest support, Firefox policies, 1Password, `environment.systemPackages`.

**home-manager/** modules:
- `home.nix` - entry point, imports all modules below
- `ssh.nix` - 1Password agent socket, GitHub identities
- `git.nix` - aliases and settings
- `zsh.nix` - Prezto framework, shell aliases
- `tmux.nix` - backtick prefix, plugins, powerline
- `terminal.nix` - alacritty, starship, ripgrep, zoxide, eza, bat, fd, fzf, mcfly
- `nixvim.nix` - declarative Neovim with embedded Lua
- `ai.nix` - Claude Code support

## Conventions

- System packages/services go in `nixos/configuration.nix`; user packages/settings go in Home Manager modules
- Editor changes belong in `home-manager/nixvim.nix` (mixes Nixvim options with embedded Lua)
- SSH uses `~/.1password/agent.sock` with host-specific GitHub identities
- Zsh uses Prezto framework configured in `home-manager/zsh.nix`
- Flakes only see tracked files - `git add` new modules before importing
- Keep new flake inputs aligned with existing 25.11 pins
- `nixos/hardware-configuration.nix` is generated - only change for real hardware updates
