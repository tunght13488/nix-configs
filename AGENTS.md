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
make home-build # build home-manager config only
make os-build   # build NixOS config only
make os-test    # test NixOS config only
make home       # home-manager switch --flake ".#tung@nixos-vmware"
make os         # switch NixOS config on the host
make update    # nix flake update
make clean     # nix-collect-garbage
make format    # format all .nix files with nixpkgs-fmt

nix flake show --no-write-lock-file   # validate without touching flake.lock
nix flake check --no-write-lock-file  # deeper evaluation check
nix fmt                                 # format via flake formatter
nixpkgs-fmt <file>                      # format single file (installed system-wide)
```

For AI agents: only run `make home-build`, `make os-build`, or `make os-test` for verification. Never run `make home`, `make os`, `nh ... switch`, or `nixos-rebuild switch`.

Use `make home-build` after editing home-manager modules; use `make os-build` after editing `nixos/`. Use `make os-test` only when you specifically need test-mode evaluation.

**IMPORTANT**: `make os` and `nixos-rebuild switch` require sudo and will fail without a terminal. Do NOT run them. Verify with `make os-build` or `make os-test`, then ask the user to run `make os` themselves if they want to apply the system.

## Architecture

Flake-based NixOS config for one machine (`nixos-vmware`, user `tung`).

**Flake inputs are pinned to the `25.11` release branches** — `nixos-25.11`, `home-manager/release-25.11`, `nixvim/nixos-25.11`. A separate `nixpkgs-unstable` input is available for bleeding-edge packages via the `pkgs.unstable` overlay (see `overlays/default.nix`).

**Standard structure** follows [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs):
- `pkgs/` — custom packages and shared package helpers (accessible via `nix build .#name` or overlays)
- `overlays/` — nixpkgs overlays (additions, modifications, unstable-packages, phps)
- `modules/nixos/` — reusable NixOS modules
- `modules/home-manager/` — reusable home-manager modules (ngrok, php-config)
- `modules/shared/` — modules imported by both NixOS and home-manager (e.g. `php-config.nix`)

**`nixos/configuration.nix`** imports:
- `inputs.self.nixosModules.php-config` — centralized PHP INI options
- `./hardware-configuration.nix` — generated, do not edit unless hardware changed
- `./php-fpm.nix`, `./nginx.nix`, `./mysql.nix` — local dev web stack
- `./nix-ld.nix` — dynamic linking support for unpackaged binaries

**`home-manager/home.nix`** imports (full list):
`agenix.nix`, `ngrok.nix`, `php.nix`, `ssh.nix`, `git.nix`, `zsh.nix`, `tmux.nix`, `fonts.nix`, `terminal.nix`, `ai.nix`, `aws.nix`, `go.nix`
Plus `inputs.self.homeManagerModules.ngrok`, `inputs.self.homeManagerModules.php-config`, `inputs.nixvim.homeModules.nixvim`; Neovim config lives in `./nixvim.nix` via `programs.nixvim.imports`.

## Dev Shells (local projects via direnv)

`flake.nix` exposes `devShells.x86_64-linux` for project-local PHP/Java/Node envs:

| Shell | Stack |
|-------|-------|
| `middleware` | PHP 8.1 + Composer (EOL, phps overlay) |
| `prbot` | PHP 8.1 + Composer |
| `v3` | PHP 8.3 + Composer |
| `fc-es-starter-pack` | JDK 8 + Maven 3.6.3 + Node.js |
| `fc-omx` | Node 22 + Yarn |

To add a project: add a shell in `flake.nix`, then in the project root: `use flake /home/tung/code/nix-configs#<shell-name>` in `.envrc`, then `direnv allow`.

## PHP Versioned Binaries

`home-manager/php.nix` installs `php81`, `php82`, `php83` versioned binaries (e.g. `php81`, `php81-fpm`, `php81ize`). Default `php`/`php-fpm`/`composer` point to 8.3 via `lib.hiPrio`. To change the default, update the `hiPrio` block in `home-manager/php.nix`.

PHP INI settings and wrapper helpers live in `pkgs/php-lib.nix` and are exposed as `pkgs.phpLib` via the `additions` overlay (see `overlays/default.nix`). Edit `pkgs/php-config.nix` to change INI settings across all consumers (NixOS php-fpm, home-manager CLI wrappers, devShells).

Centralized PHP configuration uses `phpConfig.*` options defined in `modules/shared/php-config.nix`:
- `phpConfig.common` — INI applied to all versions (FPM + CLI)
- `phpConfig.fpm` — INI applied to all versions, FPM only
- `phpConfig.cli` — INI applied to all versions, CLI only
- `phpConfig.versions.<ver>.common` — per-version INI (both FPM + CLI)
- `phpConfig.versions.<ver>.fpm` — per-version FPM-only INI
- `phpConfig.versions.<ver>.cli` — per-version CLI-only INI

Computed derivations are available via `config.phpConfig._lib.versions.<ver>.*` (in modules) or `pkgs.phpLib <config>` (in devShells).

Local test sites are served by system nginx: `http://php81.local`, `http://php82.local`, `http://php83.local` (hosts entries in `nixos/configuration.nix`).

## Conventions

- **Do not invent new top-level directories.** Place files in the existing structure:
  - `pkgs/` — custom packages, shared package helpers, and builder functions (exposed via overlays)
  - `overlays/` — nixpkgs overlays (defined in `overlays/default.nix`)
  - `modules/nixos/` — reusable NixOS modules (with `mkEnableOption`/`mkIf`)
  - `modules/home-manager/` — reusable home-manager modules (with `mkEnableOption`/`mkIf`)
  - `modules/shared/` — modules imported by both NixOS and home-manager (e.g. `php-config.nix`)
  - `nixos/` — NixOS system configuration files
  - `home-manager/` — personal home-manager configuration files
  - `secrets/` — agenix-encrypted secrets
- System packages/services → `nixos/configuration.nix`; user packages/settings → Home Manager modules
- Editor config → `home-manager/nixvim.nix` (mixes Nixvim options with embedded Lua — follow that pattern)
- Zsh → `home-manager/zsh.nix` (Prezto); tmux backtick prefix → `home-manager/tmux.nix`
- SSH uses `~/.1password/agent.sock`; GitHub identity changes belong in `home-manager/ssh.nix`
- `allowUnfree = true` is active in both layers; `allowUnfreePredicate = _: true` is also active in home-manager (workaround for [home-manager#2942](https://github.com/nix-community/home-manager/issues/2942))
- **New files must be `git add`ed before nix evaluation can import them**
- Keep new flake inputs on the 25.11 release branches (matching existing inputs); use `pkgs.unstable` for bleeding-edge packages

## Nix Code Style

- **Formatting**: Use `nixpkgs-fmt` (enforced by `make format`). Run it after editing any `.nix` file.
- **Function arguments**: Use destructuring with `,` and line breaks: `{ config, lib, pkgs, ... }:`
- **Let/in**: Place `let` on its own line, indent bindings 2 spaces, place `in` at the same level as `let`.
- **Attrsets**: Prefer trailing commas in multi-line attrsets and lists. Use `inherit` for passing through variables.
- **Modules**: Reusable modules must use `mkEnableOption` + `mkIf` pattern. Place them in `modules/nixos/` or `modules/home-manager/`.
- **Comments**: Use `#` for single-line comments. Add a header comment to new files explaining purpose and consumers.
- **Strings**: Prefer `''` indented strings for multi-line shell scripts and configuration blocks. Use `"` for single-line strings.
- **Paths**: Use `./relative/path.nix` for local imports. Do not string-interpolate paths.
- **Options**: Use `lib.mkOption` with `type`, `default`, `description`, and `example` for module options.

## Looking Up Home Manager Options

Do NOT guess option names. Verify before use:
- Module source: `https://github.com/nix-community/home-manager/blob/release-25.11/modules/programs/<name>.nix`
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
