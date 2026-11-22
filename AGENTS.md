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
make os-boot    # stage NixOS config as boot default, activate on next reboot (use for major upgrades)
make home       # home-manager switch --flake ".#tung@nixos-vmware"
make os         # switch NixOS config on the host
make update    # nix flake update
make clean     # nix-collect-garbage
make format    # format all .nix files with nixpkgs-fmt

nix flake show --no-write-lock-file   # validate without touching flake.lock
nix flake check --no-write-lock-file  # deeper evaluation check
nix fmt                                 # format via flake formatter
nixpkgs-fmt <file.nix>                  # format a single .nix file (installed system-wide)
                                        # never pass a non-.nix file: it rewrites it as Nix
```

For AI agents: the runnable Makefile targets are `make format`, `make home-build`, `make os-build`, and `make update`. `make os`, `make os-boot`, `make home`, `make clean`, and `make os-test` are reserved for humans — never run them. This is a policy, not an enforced gate; the Makefile has no guards.

Use `make home-build` after editing home-manager modules; use `make os-build` after editing `nixos/`.

**IMPORTANT**: `make os` and `make home` require sudo and a terminal, and `make os-test` activates a test generation on the running system. The user runs those themselves if they want to apply changes.

For major NixOS version upgrades (e.g. 25.11 → 26.05), humans use `make os-boot` + reboot instead of `make os`: plain `switch` restarts the display manager mid-activation, which kills the GNOME session (and the terminal running the switch) and can leave a black screen with an unregistered generation. `boot` stages the generation in GRUB without touching the running system; the previous generation stays bootable as a fallback.

## Architecture

Flake-based NixOS config for one machine (`nixos-vmware`, user `tung`).

**Flake inputs are pinned to the `26.05` release branches** — `nixos-26.05`, `home-manager/release-26.05`, `nixvim/nixos-26.05`. A separate `nixpkgs-unstable` input is available for bleeding-edge packages via the `pkgs.unstable` overlay (see `overlays/default.nix`). Exception: `nixpkgs-2511` stays pinned to `nixos-25.11` — it supplies `mysql80` (dropped from newer nixpkgs, upstream EOL) for the local dev stack via the `mysql80-packages` overlay.

**Standard structure** follows [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs):
- `pkgs/` — custom packages and shared package helpers (accessible via `nix build .#name` or overlays)
- `overlays/` — nixpkgs overlays (additions, modifications, unstable-packages, phps, mysql80-packages)
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
| `middleware` | PHP 8.3 + Composer |
| `prbot` | PHP 8.2 + Composer |
| `v3` | PHP 8.3 + Composer |
| `fc-es-starter-pack` | JDK 8 + Maven 3.6.3 + Node.js |
| `fc-omx` | Node 22 + Yarn |

To add a project: add a shell in `flake.nix`, then in the project root: `use flake /home/tung/code/nix-configs#<shell-name>` in `.envrc`, then `direnv allow`.

## PHP Versioned Binaries

`home-manager/php.nix` installs `php82`, `php83` versioned binaries (e.g. `php82`, `php82-fpm`, `php82ize`). Default `php`/`php-fpm`/`composer` point to 8.3 via `lib.hiPrio`. To change the default, update the `hiPrio` block in `home-manager/php.nix`.

PHP INI settings and wrapper helpers live in `pkgs/php-lib.nix` and are exposed as `pkgs.phpLib` via the `additions` overlay (see `overlays/default.nix`). Edit `pkgs/php-config.nix` to change INI settings across all consumers (NixOS php-fpm, home-manager CLI wrappers, devShells).

Centralized PHP configuration uses `phpConfig.*` options defined in `modules/shared/php-config.nix`:
- `phpConfig.common` — INI applied to all versions (FPM + CLI)
- `phpConfig.fpm` — INI applied to all versions, FPM only
- `phpConfig.cli` — INI applied to all versions, CLI only
- `phpConfig.versions.<ver>.common` — per-version INI (both FPM + CLI)
- `phpConfig.versions.<ver>.fpm` — per-version FPM-only INI
- `phpConfig.versions.<ver>.cli` — per-version CLI-only INI

Computed derivations are available via `config.phpConfig._lib.versions.<ver>.*` (in modules) or `pkgs.phpLib <config>` (in devShells).

Local test sites are served by system nginx: `http://php82.local`, `http://php83.local` (hosts entries in `nixos/configuration.nix`).

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
- Keep new flake inputs on the 26.05 release branches (matching existing inputs, except `nixpkgs-2511` which must stay on `nixos-25.11`); use `pkgs.unstable` for bleeding-edge packages

## Nix Code Style

- **Formatting**: Use `nixpkgs-fmt` only on files ending in `.nix` (enforced by `make format`). Run it after editing any `.nix` file; prefer `make format`, which selects only `.nix` files. Never point it at a Dockerfile, shell script, Markdown, TOML or any other non-Nix file: it treats the input as Nix and rewrites it into broken syntax without erroring.
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
- Module source: `https://github.com/nix-community/home-manager/blob/release-26.05/modules/programs/<name>.nix`
- Search docs (large — use targeted query): `https://nix-community.github.io/home-manager/options.xhtml`

## Shell Aliases (active in this environment)

| Alias | Actual command |
|-------|----------------|
| `cat` | `bat --paging=never --style=plain` |
| `du` | `ncdu` |

Do not use `command ls` etc. — it triggers repeated approval prompts. Run aliases directly.

## Sandboxed Pi (`pi-box`)

`pi-box` runs Pi in a per-project nono capability sandbox instead of on the host, so the agent
never sees `~/.aws`, `~/.ssh`, or the 1Password socket. Nono enforces the grant set with the
kernel (Landlock), so ungranted paths are unreadable rather than merely unmounted. Installed
by `home-manager/pi-sandbox.nix`; the wrapper is `home-manager/pi-box.sh`. Nono itself is a
pinned upstream release (see `pkgs/nono.nix`, currently 0.82.0) and is on `PATH` as `nono`.

```bash
pi-box                    # start Pi in the current directory's sandbox
pi-box -p "run the tests" # pass arguments to Pi (non-interactive here)
pi-box init               # scaffold pi-box.profile.json (default template)
pi-box init php83         # scaffold from a named template
pi-box init --list        # list the available templates
pi-box init --force php83 # back up and overwrite an existing pi-box.profile.json
pi-box profile            # print the per-run overlay profile and exit
pi-box help               # usage summary
```

The policy is split in two, and nono merges them itself:

- The **base profile** `~/.config/nono/profiles/pi-box.json`, deployed by home-manager: the
  default grants below, the network allowlist, and the environment deny-list. It is static.
- The **per-run overlay** `pi-box-overlay-<project>`, generated into the same directory: the
  parts that cannot be static — the workspace grant, a worktree's git common directory, the
  repository root `AGENTS.md`, the herdr socket, and the GitHub token route (when the token
  file exists).

A project's `pi-box.profile.json` is a standard nono profile with `"extends": "pi-box"`, and
`pi-box` runs `nono run --profile <project profile|pi-box> --extends pi-box-overlay-<project>`;
nono unions the filesystem grants across the chain. `pi-box profile` prints the overlay and
the base lives next to it — together they are the whole policy, which is the fastest way to
see what a project actually grants.

Default grants: the project directory (read-write, at its host absolute path), `~/.pi/agent`
(read-write — provider credentials, settings, sessions, skills and trust are shared with host
Pi, so no login step is needed), `~/.cache` (read-write, for application and tool caches),
`/tmp` (read-write; `pi-box` sets `TMPDIR=/tmp`), `~/.config/git`, `~/.config/gh` and
`~/.config/nvim` (read-only), `~/.local/state/nvim` and `~/.local/share/nvim` (read-write —
Neovim's shaDa, plugin logs and data), `~/.config/github-copilot` (read-write — the nvim
Copilot client's auth store), `/nix` (read-only — the Nix store, needed for the targets of
home-manager's symlinks and for the PATH the generated launcher sets), and
`~/.pi/sandbox/runtime` (read-only — the launcher and profile files). Worktrees whose git
directory sits outside the workspace also get that git directory (read-write) and the
repository root's `AGENTS.md` (read-only). The default base profile leaves `~/.aws`, `~/.ssh`,
the 1Password agent socket, and all other unlisted host paths inaccessible. Pi's Ctrl+G editor
uses `nvim` via `EDITOR=nvim` unless the shared Pi settings specify an explicit `externalEditor`.

Worktree projects also get their git directory: when `git rev-parse --git-common-dir` for the
workspace resolves outside it (the bare+worktree layout used here), `pi-box` grants that
directory read-write, so `git status`, `git log` and commits work inside the sandbox. Plain
single-directory repositories get no extra grant.

Herdr detects a pane's agent by its foreground process, so `pi-box` execs nono under the name
`pi` (a symlink to the unwrapped nono ELF with `exec -a pi`), making the pane foreground read
as `pi` exactly like a host pi pane. Agent states (working, blocked, idle) come from Pi's own
herdr extension: the sandboxed session is a host process, so it connects to the herdr socket
directly, granted through the profile. There is no relay process and no session-path mapping
any more — the session path herdr types is already a host path.

Herdr resumes a restarted pane by typing `pi --session <host path>` into the pane shell, which
would run the agent unsandboxed. A `pi` zsh function in `home-manager/zsh.nix` routes exactly
that invocation (only when `HERDR_ENV=1` and the path is under `~/.pi/agent/`) through
`pi-box`. Every other `pi` invocation runs the real binary, including all of them outside
herdr panes. Limitation: this relies on the pane shell being zsh.

Network is default-deny. The profile uses nono's `developer` network profile (LLM APIs,
package registries, GitHub, sigstore, docs), adds pi's own providers explicitly — GitHub
Copilot (`*.githubcopilot.com`, its business proxy `proxy.business.githubcopilot.com`, plus the
`/copilot_internal/**` OAuth exchange path on api.github.com), OpenCode (`opencode.ai`,
`api.opencode.ai`), and the pi-web-access providers (Exa, Tavily, Brave Search, Serper, Kagi,
Jina) — and everything else fails closed with a 403 from the local proxy. Arbitrary-URL
reading works through `r.jina.ai` when the Jina reader fallback is enabled in
`~/.pi/agent/web-search.json`; otherwise per-project domains go in `pi-box.profile.json`.
Blocked attempts are visible with `nono audit list` / `nono audit show`.

**GitHub access is endpoint-restricted.** `pi-box` reads `~/.pi/sandbox/gh-token` (mode 600)
when present and declares it as a nono credential route: the token stays outside the sandbox,
`gh` sees only a phantom in `GH_TOKEN`, and the proxy swaps in the real token per request. The
route allows `GET /user`, `GET /repos/**`, `GET /search/**`, `GET /notifications`,
`POST /repos/*/pulls`, `POST /copilot_internal/**` (the Copilot OAuth exchange) and
`POST /graphql`; everything else, including every DELETE and PATCH, is refused. The `POST /graphql` rule is the loose end — GraphQL is one endpoint, so path rules
cannot separate a query from a mutation.

```bash
mkdir -p ~/.pi/sandbox && install -m 600 /dev/null ~/.pi/sandbox/gh-token
# paste the token, then Ctrl-D
cat > ~/.pi/sandbox/gh-token
```

**The token is a classic PAT with `repo` + `read:org`, and it is write-capable.** Classic
tokens have no read-only scope for private repos, and `Secretlabsg` blocks fine-grained PATs
needing org approval, so a classic PAT is the only token that works against that org today.
The endpoint rules are what keep that token from touching repository settings, secrets or
deletions; they cannot stop a GraphQL mutation or a `git push` allowed by the token's scopes.
Without the file the sandbox still starts; `gh` just reports unauthenticated.

GitHub remotes written in SSH form work anyway: the wrapper exports
`url.https://github.com/.insteadOf=git@github.com:` for the sandboxed process, so those
operations go over HTTPS with the host credential helper, and each checkout keeps its
configured `origin` untouched. That rewrite covers the `git@github.com:ORG/REPO.git` form
only — `ssh://git@github.com/...` URLs and remotes on any other SSH host are not rewritten and
still fail in the sandbox, since the 1Password agent socket is deliberately never granted.
Note that `git remote get-url` prints the rewritten HTTPS URL while
`git config --get remote.origin.url` shows the stored SSH value.

Pi, Neovim, the language toolchains and the Nix CLI all come from the host (home-manager and
project devShells); the sandbox contributes policy, not images. Pi's version in the sandbox is
whatever home-manager installs.

### Templates

The stack templates live in `home-manager/pi-box-templates/` (the source of truth) and are
deployed by home-manager to `~/.pi/sandbox/templates/`, one directory each. A template is a
`pi-box.profile.json` with the grants that stack needs; toolchains come from the host or the project's
devShell.

| Template | Grants |
|----------|--------|
| `default` | empty profile with commented fields |
| `php83` | `connect_port [3306]`, `DB_HOST=127.0.0.1` |
| `php82` | same as `php83` |
| `java8` | `filesystem.allow ~/.m2` for the Maven cache |
| `node22` | `filesystem.allow ~/.npm, ~/.yarn` |
| `knowledge-assistant` | `filesystem.allow ~/.npm` for the npx cache |
| `nix-configs` | `~/.local/state/nix`, the Nix daemon socket |

Use `php83` for Laravel 11/12 projects, `php82` for older Laravel (9/10) and any project that
pins PHP 8.2, `java8` for the Fluent Commerce backend, `node22` for the frontend,
`knowledge-assistant` for workspaces that validate Mermaid blocks in Markdown, and
`nix-configs` for this repository, whose Makefile targets are meant to run inside the sandbox.

```bash
pi-box init php83     # in the project root, then adjust pi-box.profile.json as needed
```

Adding a template means adding a directory under `home-manager/pi-box-templates/` with a
`pi-box.profile.json`, and force-adding it to git (`git add -f`), because the global gitignore
ignores the scaffold name `pi-box.profile.json` everywhere.

### Nix builds in the sandbox (`nix-configs` template)

Adopt it in this repository with `pi-box init --force nix-configs` (backups are written
first). The template grants the Nix daemon socket and `~/.local/state/nix`. The base profile
already grants `~/.cache`, and `/nix` is readable by default, so `nix build`, `nh` and
`nixos-rebuild` run as daemon clients against the host Nix. Nix's own build sandbox runs
daemon-side, so it is unaffected by the pi-box sandbox and stays hermetic.

`make home-build` and `make os-build` are the agent-safe targets (see Commands above);
`make home`, `make os`, `make os-boot`, `make os-test` and `make clean` are human-only.

### Per-project files (untracked, gitignored)

`pi-box init [template]` writes `pi-box.profile.json` from the chosen template. It is in
`programs.git.ignores`, so it stays untracked in every repository — which also means each new
worktree starts without it and needs `pi-box init` again.

An existing file is not touched by default: `pi-box init` asks once before replacing it (and
does nothing when there is no terminal to ask), the previous version is copied to
`pi-box.profile.json.<YYYYmmdd-HHMMSS>.bak`, and `--force` skips the prompt while still
writing the backup.

The file is a standard nono profile (validate it with `nono profile validate
pi-box.profile.json`) that extends the deployed base by name; nono merges it, so any field of
the nono profile schema is honored and anything outside the schema fails validation at run
time:

```json
{
  "extends": "pi-box",
  "filesystem": {
    "allow": ["~/.m2"],              // extra read-write paths
    "read": ["/host/path"],          // extra read-only paths
    "read_file": ["/host/file"],     // single read-only files
    "unix_socket": ["/path/to.sock"] // AF_UNIX sockets the sandbox may connect to
  },
  "network": {
    "connect_port": [3306],          // outbound ports (a host database)
    "listen_port": [8080],           // ports the sandbox may listen on
    "allow_domain": ["example.com"]  // extra allowed domains
  },
  "environment": {
    "set_vars": { "DB_HOST": "127.0.0.1" }
  }
}
```

`gh = false`, `volumes` and `privileged` are gone: the gh config grant is unconditional (the
token file in `~/.pi/sandbox` is the on/off switch), and named volumes and nested namespaces
only made sense for the Docker backend. Grant the host path instead.

## Scratch Space

`.tmp/` (repo root) is gitignored — use it for temp files and test outputs instead of `/tmp`.

<!-- OPENWIKI:START -->

## OpenWiki

This repository has a generated `openwiki/` evidence index. It is optional just-in-time context, not required startup reading.

- Do not enumerate, preload, or search wikis at task start. Use retrieval when the user asks for it, when unfamiliar architecture or dependency behavior materially affects the task, or when source inspection leaves an important uncertainty. Stop once the question is grounded.
- When those conditions apply and OpenWiki retrieval tools are available, use `openwiki_search` for just-in-time context and `openwiki_read` for the relevant complete sections. If search returns `workspace_required`, ask which listed workspace to use and retry with its ID.
- Use `openwiki_list_workspaces` or `openwiki_list_wikis` when workspace membership itself needs to be discovered.
- If the retrieval tools are unavailable, read `openwiki/quickstart.md` and follow its links to the relevant pages.
- Treat source code and tests as authoritative. A brief's unknowns and review items are verification gaps, not automatic requirements.
- Prefer the narrowest quiet validation that proves the changed behavior. Preserve complete failure output.

The scheduled OpenWiki GitHub Actions workflow refreshes the repository wiki. Do not hand-edit generated OpenWiki pages unless explicitly asked; prefer updating source code/docs and letting OpenWiki regenerate.

<!-- OPENWIKI:END -->
