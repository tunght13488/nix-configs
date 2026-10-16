# Proposal

## Why

pi currently runs as a self-managed install (`~/.pi/agent/install/releases/1.2.0`, ~153 MB, self-updating) whose launcher (`~/.pi/agent/bin/pi`, shadowed by the `~/.local/bin/pi` entrypoint symlink) sits ahead of the Home Manager profile on PATH, so the flake can never own the binary. Worse, the agent process runs unconfined with the user's full credential surface: AWS credentials, SSH keys via the 1Password agent socket, the gh OAuth token, an npm-publish-capable `~/.npmrc` chain, and herdr control — the last of which can spawn entirely unjailed panes. The goal: pi becomes flake-managed and the agent gets only the checked-out code plus an environment to run tests, static analysis, lint, and nix evaluation — no credentials.

## What Changes

- Add the `lukasl-dev/pi.nix` flake input (packages pi v1.2.0 — exact version parity with the current install) and enable its Home Manager module (`programs.pi.coding-agent`).
- Enable the module's jail (bubblewrap via jail.nix) with a tight permission set: cwd read-write, `~/.pi/agent` read-write (always, by the module), full `/nix/store` read-only, nix daemon socket, system `/etc/nix` read-only, gh config read-only, openspec CLI, and the base dev toolchain (`nix`, `direnv`, `make`, `gh`, `nixpkgs-fmt`).
- Expose the four worktree-based repos the agent works in (`nix-configs`, `netsuite-middleware`, `fc-es-starter-pack`, `fc-omx`) read-only at their roots — with `.bare` read-write for commits and read-only sibling worktrees — plus persistent language dependency caches (`~/.m2`, `~/.npm`, `~/.cache/yarn`, `~/.cache/composer`).
- Provide project toolchains inside the jail: PHP 8.1/8.2/8.3 with versioned Composer (the same `phpConfig` wrappers the system layer installs), JDK 8 + Maven 3.6.3 + Node.js + jq (the fc-es-starter-pack set), and Node 22 + Yarn (the fc-omx set).
- Deny every credential surface inside the jail: `~/.aws`, `~/.ssh`, the 1Password agent socket, `~/.npmrc`, the token-bearing `~/.config/nix/nix.conf`, and the herdr client socket.
- Make git push work from inside the jail without SSH: a jail-local minimal gitconfig rewrites `git@github.me:` remotes to `https://github.com/` and uses `gh auth git-credential` as the credential helper.
- Keep herdr's agent-state visibility via herdr's screen-manifest detection: export `HERDR_AGENT=pi` on the host-visible wrapper (jail.nix `add-runtime`), and forward none of the `HERDR_*` socket variables so the socket extension stays inert.
- **BREAKING (workflow)**: the jailed agent can no longer push over SSH, use the aws CLI, control herdr, or run `make update` / `make home` / `make os` — the latter three are deliberate host-side policy (`make home-build` / `make os-build` still run inside the jail).
- Retire the self-managed install after verification: remove the entrypoint symlink and launcher, then `~/.pi/agent/install` (frees ~153 MB). pi's version becomes managed by the flake input (`pi update` defers to the package manager by design).
- Add `pi.cachix.org` (+ nix-community cache) substituters to system nix settings so the pi package substitutes instead of building from source.
- Preserve all agent-dir state untouched: `settings.json` stays unmanaged (the module declares no `settings`/`rules`/`skills`), auth/sessions/trust, npm extensions (`~/.pi/agent/npm`), the herdr skill file, and `AGENTS.md` keep their current mechanisms.

## Capabilities

### New Capabilities

- `pi-coding-agent`: the pi coding agent as a flake-provided, jail-contained user tool — binary provenance from the pi.nix input, agent-directory state preservation, self-managed install retirement, the sandbox's allowed and denied surfaces, herdr state visibility without socket access, and binary-cache substituters.

### Modified Capabilities

None. `herdr-agent-skill`'s requirements concern skill file availability (derivation, symlink, discovery), which is unchanged: the skill file still exists and loads; its herdr control commands simply fail at runtime inside the jail.

## Impact

- `flake.nix`: new `pi` input (follows `nixpkgs-unstable`).
- `home-manager/home.nix`: import `inputs.pi.homeModules.default` + new `home-manager/pi.nix` (module config, jail permissions, jail-local gitconfig, openspec binds).
- `nixos/configuration.nix`: `nix.settings` substituters/trusted keys for `pi.cachix.org`.
- `~/.pi/agent`: `install/`, `bin/pi`, and `~/.local/bin/pi` removed at cutover; everything else preserved.
- Project repos (`netsuite-middleware`, `fc-es-starter-pack`, `fc-omx`): no edits needed there — their roots, `.bare` dirs, toolchains, and dependency caches become jail-visible via the permission list.
- Agent git workflow: pushes go over https (insteadOf rewrite) instead of SSH inside agent sessions.
- herdr integration: socket extension inert inside the jail; state reported via screen detection (`HERDR_AGENT=pi`).
- Verification depends on manual session checks (new terminal, TUI, herdr pane) — the cutover sequence must keep live sessions safe: the currently-running pi session uses `install/releases/1.2.0` until it exits.
