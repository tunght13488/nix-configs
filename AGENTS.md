# AGENTS.md

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
make home      # home-manager switch --flake ".#tung@nixos-vmware"
make system    # sudo nixos-rebuild switch --flake ".#nixos-vmware"
make update    # nix flake update
make clean     # nix-collect-garbage

nix flake show --no-write-lock-file   # validate without touching flake.lock
nixfmt <file>                          # format after editing (installed system-wide)
```

Use `make home` after editing home-manager modules; `make system` after editing `nixos/`.

**IMPORTANT**: `make system` and `sudo nixos-rebuild switch` require sudo and will fail without a terminal. Do NOT run them. Instead, run `nixos-rebuild build --flake ".#nixos-vmware"` to verify the build succeeds, then ask the user to run `make system` themselves.

## Architecture

Flake-based NixOS config for one machine (`nixos-vmware`, user `tung`).

**Flake inputs are on rolling branches** — `nixos-unstable`, `home-manager/master`, `nixvim/main` — not pinned to 25.11 (ignore any docs or comments claiming otherwise).

**`nixos/configuration.nix`** imports:
- `./hardware-configuration.nix` — generated, do not edit unless hardware changed
- `./php-fpm.nix`, `./nginx.nix`, `./mysql.nix` — local dev web stack
- `./nix-ld.nix` — dynamic linking support for unpackaged binaries

**`home-manager/home.nix`** imports (full list):
`ssh.nix`, `git.nix`, `zsh.nix`, `tmux.nix`, `fonts.nix`, `terminal.nix`, `ai.nix`, `aws.nix`
Plus `inputs.nixvim.homeModules.nixvim`; Neovim config lives in `./nixvim.nix` via `programs.nixvim.imports`.

## Dev Shells (local projects via direnv)

`flake.nix` exposes `devShells.x86_64-linux` for project-local PHP/Java envs:

| Shell | Stack |
|-------|-------|
| `middleware` | PHP 8.1 + Composer (EOL, phps overlay) |
| `prbot` | PHP 8.1 + Composer |
| `v3` | PHP 8.3 + Composer |
| `fc-es-starter-pack` | JDK 8 + Maven 3.6.3 + Node.js |

To add a project: add a shell in `flake.nix`, then in the project root: `use flake /home/tung/code/nix-configs#<shell-name>` in `.envrc`, then `direnv allow`.

## PHP Versioned Binaries

`home.nix` installs `php81`, `php82`, `php83` versioned binaries (e.g. `php81`, `php81-fpm`, `php81ize`). Default `php`/`php-fpm`/`composer` point to 8.3 via `lib.hiPrio`. To change the default, update the `hiPrio` block in `home.nix`.

Local test sites are served by system nginx: `http://php81.local`, `http://php82.local`, `http://php83.local` (hosts entries in `nixos/configuration.nix`).

## Conventions

- System packages/services → `nixos/configuration.nix`; user packages/settings → Home Manager modules
- Editor config → `home-manager/nixvim.nix` (mixes Nixvim options with embedded Lua — follow that pattern)
- Zsh → `home-manager/zsh.nix` (Prezto); tmux backtick prefix → `home-manager/tmux.nix`
- SSH uses `~/.1password/agent.sock`; GitHub identity changes belong in `home-manager/ssh.nix`
- `allowUnfree = true` is active in both layers; the commented `allowUnfreePredicate` block is NOT active
- **New files must be `git add`ed before nix evaluation can import them**
- Keep new flake inputs on unstable/master (matching existing inputs), not 25.11

## Looking Up Home Manager Options

Do NOT guess option names. Verify before use:
- Module source: `https://github.com/nix-community/home-manager/blob/master/modules/programs/<name>.nix`
- Search docs (large — use targeted query): `https://nix-community.github.io/home-manager/options.xhtml`

## Shell Aliases (active in this environment)

| Alias | Actual command |
|-------|----------------|
| `cat` | `bat --paging=never --style=plain` |
| `find` | `fd` |
| `grep` | `rg` |
| `ls` | `eza --group-directories-first` |
| `du` | `ncdu` |

Do not use `command ls` etc. — it triggers repeated approval prompts. Run aliases directly.

## Scratch Space

`.tmp/` (repo root) is gitignored — use it for temp files and test outputs instead of `/tmp`.
