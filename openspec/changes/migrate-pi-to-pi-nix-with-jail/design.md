# Design

## Context

See `proposal.md` for motivation. Current state that constrains the design:

- pi runs as a self-managed install: `~/.pi/agent/bin/pi` (launcher reading `install/current-version` = 1.2.0) with entrypoint symlink `~/.local/bin/pi`; both sit ahead of `~/.nix-profile/bin` on PATH, so they shadow any flake-provided `pi` until removed.
- `pi.nix` (lukasl-dev) packages pi **v1.3.0** at its current HEAD while the running self-managed install is **v1.2.0**, so this change also carries a minor pi upgrade; it provides a Home Manager module whose `settings`/`mcp` options jq-merge into `~/.pi/agent` files only when declared; `rules`/`skills`/`extensions` are per-invocation CLI flags, not managed files. The jail (jail.nix bubblewrap) is built at the package level, so the HM module works standalone. pi upstream explicitly supports Nix-provided installs (`pi update` defers to the package manager).
- Already Home-Manager-owned: `~/.pi/agent/AGENTS.md` (`home-manager/ai.nix`) and `~/.pi/agent/skills/herdr/SKILL.md` (`home-manager/herdr.nix`). Unmanaged agent-dir state: `settings.json` (hand-maintained), `auth.json`, `trust.json`, `sessions/`, `~/.pi/agent/npm` (three npm extensions — pi resolves these via `join(agentDir, "npm")`, independent of the wrapper's `NPM_CONFIG_PREFIX` default), `extensions/herdr-agent-state.ts` (herdr-managed, pure-outbound socket reporting: `pane.report_agent*` methods, gated on `HERDR_ENV`/`HERDR_SOCKET_PATH`/`HERDR_PANE_ID` env).
- Git identity lives at `~/.config/git/config` (HM symlink; large alias set, `credential.helper = gh auth git-credential` for github.com). Repo remotes are `git@github.me:` — an SSH host alias backed by the 1Password agent. `~/.config/gh/hosts.yml` holds the gh OAuth token; `~/.npmrc` only sets a prefix (no token).
- jail.nix base: tmpfs `$HOME` and `/tmp`, fake `/proc`//`/dev`, coreutils, env cleared except `LANG`/`HOME`/`TERM`, only the app's own closure visible in `/nix/store` unless widened. Combinators: `network`, `mount-cwd`, `readonly`/`readwrite`/`try-ro-bind`/`try-rw-bind`, `add-pkg-deps`, `add-path`, `add-runtime` (host-side, before bwrap starts), `write-text`, `set-env`, `try-fwd-env`, `noescape`.
- herdr (v0.9.5, flake input `herdrdev/herdr` — public) exposes a client socket at `~/.config/herdr/herdr-client.sock`; control through it would spawn unjailed panes (a full jail bypass). Per herdr docs (Agents / VMs and sandbox wrappers): a host-visible wrapper hides the agent process; setting `HERDR_AGENT=<agent>` on the wrapper tells herdr which screen manifest to use; a hint set only inside a VM/container is not seen.
- All nix-configs flake inputs are public (verified unauthenticated), so `nix flake update` needs no `access-tokens`; the token-bearing `~/.config/nix/nix.conf` is written by `home-manager/agenix.nix` for private-repo fetching only.
- The nix-configs repo uses git worktrees: every git operation from a worktree (e.g. `nix_main`) needs `../.bare`; commits write objects/refs there. The agent's project repos use the same layout (`.bare` confirmed in each): `netsuite-middleware` (worktrees: middleware_alpha/beta/gamma/main — PHP + Composer), `fc-es-starter-pack` (oms_backend_alpha/main/reference — JDK 8 + Maven 3.6.3 + Node.js, per the flake's dev shell), `fc-omx` (oms_frontend_main — Node 22 + Yarn).
- The PHP toolchain is system-level: `nixos/configuration.nix` installs `php81/82/83` + `composer81/82/83` (built via `config.phpConfig._lib`, exposed as `pkgs.phpLib` through the additions overlay) into the system profile; the flake's `pkgs` exposes `php81/82/83` via the phps overlay. The PHP dev shells (`mkSystemPhpShell`) exec `/run/current-system/sw/bin/phpXX` — they depend on the system profile. The projects' `.envrc` files are absent today; no cred-bearing dependency config exists (`~/.m2/settings.xml`, `~/.config/composer/auth.json`, `~/.composer/auth.json` all absent).

## Goals / Non-Goals

**Goals:**

- pi binary from the pi.nix flake input, version pinned by `flake.lock`, with the old self-managed install retired safely (live sessions keep working through cutover).
- A jail whose allowed surface is exactly: cwd rw, `~/.pi/agent` rw (module-provided), network, full `/nix/store` ro, nix daemon socket, token-free `/etc/nix`, `gh` (+ its config ro), `openspec`, dev toolchain (`nix`, `direnv`, `make`, `nixpkgs-fmt`), `~/.agents` (find-skills skill), `~/.cache/nix`.
- Git commits + pushes from inside the jail over https (insteadOf + gh credential helper), no SSH anywhere.
- herdr state visibility via screen detection with a host-side `HERDR_AGENT=pi` hint; zero herdr surface inside the jail.
- Project toolchains usable inside the jail in the agent's project folders (PHP/Composer, Java/Maven, Node/Yarn) with persistent language dependency caches.

**Non-Goals:**

- Scoped fine-grained PAT for gh (deferred hardening; current decision: readonly `~/.config/gh` bind — the OAuth token is agent-readable, accepted).
- A filtered herdr socket proxy (fallback only, if screen detection proves unusable).
- Migrating other agents (claude-code/opencode remain as-is), pi version upgrades beyond 1.2.0, managing `settings.json` declaratively.
- Jailing `make update` / `make home` / `make os` — deliberately host-side (all inputs are public so `make update` *would* work jailed; keeping it host-side is policy, not necessity).

## Decisions

### D1: Home Manager layer + pi.nix input pinning

`inputs.pi.url = "github:lukasl-dev/pi.nix"` with `inputs.pi.inputs.nixpkgs.follows = "nixpkgs-unstable"` — pi.nix's CI baseline. pi.nix has no release branches, so tracking HEAD means `make update` moves pi along with the other inputs and `flake.lock` re-pins it; it does tag releases (`v1.2.0`, `v1.3.0`), so pinning to a tag is a one-line rollback for the version upgrade alone. This input packages **v1.3.0**, so the migration includes a 1.2.0 → 1.3.0 upgrade (verified in task 4.2, including the npm extensions). Import `inputs.pi.homeModules.default` and configure in a new `home-manager/pi.nix` (personal config, follows `ai.nix`/`ngrok.nix` file pattern; imported from `home-manager/home.nix`). Alternative (NixOS module) rejected: everything pi-related here is user-level and already HM-owned.

### D2: No module resource options — keep existing mechanisms

Set `enable = true` + `jail.enable = true` and nothing else in `programs.pi.coding-agent`: `settings = {}` leaves `settings.json` untouched, `rules` unset avoids duplicating `AGENTS.md` via `--append-system-prompt` (ai.nix keeps owning it), `skills` unset (herdr.nix keeps owning the skill file), `extensions` unset (agent-dir native loading covers `herdr-agent-state.ts` and npm extensions). With no resource args the module uses the raw package as the jail entry — the agent-dir rw mount (`configPermission`) is added regardless, so nothing is lost.

### D3: Jail permission list (the core of the containment)

Permission order matters: bwrap applies binds in argument order and later mounts win at deeper paths, so the read-only repo-root binds must precede `mount-cwd`, and the `.bare` read-write binds must follow the repo-root binds. Paths are shown literally for readability; interpolate `config.home.homeDirectory` in the module.

```
# repo roots (worktree layouts): ro root (siblings + the nix-configs flake source for
# `nix develop`), rw .bare (commits). All four exist on this machine.
(readonly "/home/tung/code/nix-configs")
(readonly "/home/tung/code/netsuite-middleware")
(readonly "/home/tung/code/fc-es-starter-pack")
(readonly "/home/tung/code/fc-omx")
(rw-bind "/home/tung/code/nix-configs/.bare" "/home/tung/code/nix-configs/.bare")
(rw-bind "/home/tung/code/netsuite-middleware/.bare" "/home/tung/code/netsuite-middleware/.bare")
(rw-bind "/home/tung/code/fc-es-starter-pack/.bare" "/home/tung/code/fc-es-starter-pack/.bare")
(rw-bind "/home/tung/code/fc-omx/.bare" "/home/tung/code/fc-omx/.bare")

network                                     # model APIs, extension downloads (pi.nix default)
mount-cwd                                   # checked-out worktree rw (after ro roots so cwd wins)
(readonly "/nix/store")                     # full store ro - evaluation of arbitrary
                                            #   locked inputs, dev shells, toolchain closures
(try-readwrite "/nix/var/nix/daemon-socket")# nix build/eval via daemon (home-build, os-build, dev shells)
(try-readonly "/etc/nix")                   # system nix.conf: substituters, NO access-tokens
(try-readwrite (noescape "~/.cache/nix"))   # nix client caches (HOME is tmpfs in jail)
(try-readonly (noescape "~/.config/gh"))    # gh auth (readonly bind - accepted token visibility)
(try-ro-bind (noescape "~/.npm-global/lib/node_modules") (noescape "~/.npm-global/lib/node_modules"))
(try-ro-bind (noescape "~/.npm-global/bin/openspec") (noescape "~/.npm-global/bin/openspec"))
(try-readonly (noescape "~/.agents"))       # find-skills skill dir
(write-text "<home>/.gitconfig" <jailed gitconfig>)   # see D4

# language dependency caches (host-side mkdir so the rw binds always have a target)
(add-runtime ''mkdir -p "$HOME/.m2" "$HOME/.npm" "$HOME/.cache/yarn" "$HOME/.cache/composer"'')
(readwrite (noescape "~/.m2"))               # Maven
(readwrite (noescape "~/.npm"))             # npm cache (NOT ~/.npmrc - publish protection)
(readwrite (noescape "~/.cache/yarn"))
(readwrite (noescape "~/.cache/composer"))  # no composer auth.json exists (verified)

(add-pkg-deps [ pkgs.nix pkgs.direnv pkgs.make pkgs.nixpkgs-fmt pkgs.gh
                <project toolchains - see D8> ])
(add-runtime ''export HERDR_AGENT=pi'')     # host-side, see D5
```

Denials come for free from jail base (tmpfs home) plus omissions: `~/.aws`, `~/.ssh`, `~/.1password/agent.sock`, `~/.npmrc`, `~/.config/nix` (token nix.conf), `~/.config/herdr/herdr-client.sock` are simply not mounted. `openspec`'s `node` comes from pi's own closure PATH (the store binary suffixes `node git openssh ripgrep fd`), so no extra node exposure is needed; binding `lib/node_modules` (rather than all of `~/.npm-global`) avoids putting `yarn`/`clasp`/`fluent` on the jail PATH while tolerating npm dependency hoisting. `SSH_AUTH_SOCK` is intentionally *not* forwarded.

The worktree layout means cwd (one worktree) is not the whole repo: each of the four repos binds its root read-only (sibling worktrees become readable — useful, e.g. `oms_backend_reference` — and the nix-configs root doubles as the dev-shell flake source) with `.bare` read-write so commits work. Writes stay confined to the agent's own worktree: the "stay in your worktree" guardrail is enforced mechanically for writes and relaxed only for reads.

### D4: Jail-local minimal gitconfig (push without SSH)

HOME is tmpfs in jail, so the real `~/.config/git/config` is absent — git falls back to `~/.gitconfig`, provided via `write-text`:

```ini
[user]
    name = <from ~/.config/git/config>
    email = <from ~/.config/git/config>
[url "https://github.com/"]
    insteadOf = git@github.me:
[credential "https://github.com"]
    helper = !gh auth git-credential
[push]
    default = current
[init]
    defaultBranch = main
```

insteadOf rewrites every `git@github.me:` remote (and gh's ssh-protocol clones) to https; `gh auth git-credential` works off the readonly `~/.config/gh` bind. Alternative considered: forwarding `SSH_AUTH_SOCK` + binding `~/.ssh` — rejected, it defeats the containment goal.

### D5: herdr state via screen detection

Forward none of `HERDR_ENV`/`HERDR_SOCKET_PATH`/`HERDR_PANE_ID` (jail base already clears env) → the extension's `enabled()` fails → zero socket attempts. State comes from herdr reading the pane PTY (the TUI renders normally through bwrap) with the pi screen manifest, activated by `HERDR_AGENT=pi` on the host-visible process. `add-runtime` runs host-side before bwrap, so `export HERDR_AGENT=pi` there lands in the wrapper/bwrap environ where herdr can read it. Alternatives: filtered socket proxy (over-engineering; fallback only), binding the real socket (full jail bypass — rejected).

### D6: Cachix substituters at the system level

`nix.settings.extra-substituters` + `extra-trusted-public-keys` for `pi.cachix.org` and `nix-community.cachix.org` in `nixos/configuration.nix` (public keys from pi.nix README). Avoids building the pi npm workspace (~large) from source.

### D7: Cutover sequence (self-referential safety)

The agent doing this change runs from `install/releases/1.2.0`; the sequence must never break a live session:

1. Build + evaluate (`make home-build`, `make os-build`) — nothing installed yet.
2. User runs `make home` (+ `make os` for substituters) in a fresh terminal.
3. Verify the flake-provided binary by explicit path (`~/.nix-profile/bin/pi --version`, TUI smoke test, `pi list` shows the three npm extensions, powerline footer renders) — old launcher still shadows PATH, which is fine.
4. Remove entrypoint + launcher (`~/.local/bin/pi`, `~/.pi/agent/bin/pi`); `command -v pi` now resolves to the profile; full jailed verification (models, `make home-build` in-jail, `openspec list`, `gh auth status` + `gh pr view`, a real push, herdr state transitions in a herdr pane).
5. After no live session uses the old release: delete `~/.pi/agent/install` (~153 MB). Rollback until step 5: restore `~/.local/bin/pi` symlink (or `git revert` + `make home` and re-run the pi installer).

### D8: Project toolchains — direct versioned binaries, not dev shells

Projects and toolchains: `netsuite-middleware/middleware_alpha` (+ siblings; PHP + Composer, version per each project's `composer.json`), `fc-es-starter-pack/oms_backend_main` (JDK 8 + Maven 3.6.3 + Node.js + jq — the flake's fc-es-starter-pack dev-shell set), `fc-omx/oms_frontend_main` (Node 22 + Yarn — the flake's fc-omx dev-shell set).

Mechanism — `add-pkg-deps` with the same packages/wrappers the rest of the config already uses:

- PHP: `config.phpConfig._lib.versions.<81|82|83>.{versionedPkg, composerVersionedPkg}` plus the `_lib` default `php`/`composer` (8.3-based, matching the user-level default). These are the exact derivations the NixOS layer installs system-wide (same config → same store paths), and they match the global AGENTS.md instruction model (`php81`/`composer81`… per `composer.json`).
- Java/Node: exactly the dev-shell buildInputs — `pkgs.jdk8`, `pkgs.maven363`, `pkgs.nodejs`, `pkgs.jq`, `pkgs.nodejs_22`, `pkgs.yarn` — with `nodejs_22` ordered before `nodejs` in the `add-pkg-deps` list so bare `node` resolves to 22 (fc-omx `engines.node = 22.*`; the Java project's node usage is version-agnostic).

Why not dev shells as the primary mechanism: the PHP dev shells (`mkSystemPhpShell`, including the active `prbot` shell) exec `/run/current-system/sw/bin/phpXX` — the system profile is deliberately not mounted in the jail, so those shells are jail-inert by design; the projects' `.envrc` files are also absent today. The versioned binaries replace them. Java/Node dev shells still work when invoked explicitly (`nix develop /home/tung/code/nix-configs#fc-omx`) because their inputs are store paths (full store ro) and the nix-configs flake source is ro-bound (D3).

Language caches: HOME is tmpfs in jail, so Maven (`~/.m2`), npm (`~/.npm`), Yarn (`~/.cache/yarn`), and Composer (`~/.cache/composer`) caches would vanish per session (Java worst: full dependency re-download each time). They are bound rw; the host-side `add-runtime` `mkdir -p` (D3) guarantees the non-`try` `readwrite` binds always have a target. Verified: no cred-bearing dependency config exists today; `~/.npmrc` stays denied. If a project later needs authenticated private dependencies, that is a new, deliberate decision — those files are credentials.

## Risks / Trade-offs

- [Bind ordering: ro repo-root binds must precede `mount-cwd` and `.bare` rw binds, or cwd/`.bare` end up read-only] → Verify writes in each repo (task 5.5); jail.nix applies permissions in list order and bwrap binds shadow earlier mounts at deeper paths.
- [Composer/Maven/npm private-registry auth later needed] → No auth files bound (verified absent today); adding them would expose credentials — a deliberate future decision, not a default.
- [PHP dev shells (`mkSystemPhpShell`, incl. `prbot`) are jail-inert] → By design (system profile unmounted); the versioned binaries supersede them inside the jail.
- [Bare `node` could resolve to the wrong major] → `add-pkg-deps` order puts `nodejs_22` before `nodejs`; verify in task 5.5.
- [The pi 1.2.0 → 1.3.0 upgrade may break the three npm extensions installed under 1.2.0] → Task 4.2 verifies the TUI and `pi list` after activation; refresh with `pi update --extensions` if required; rollback for the upgrade alone is pinning `github:lukasl-dev/pi.nix/v1.2.0`.

- [bwrap `--new-session` may affect TUI behavior or herdr foreground detection] → Verify TUI rendering/resize and `herdr agent explain` on day one; herdr fallback is server env `HERDR_PROCESS_DETECTION=child-groups` (server restart); jail.nix `no-new-session` is the last resort (weakens TIOCSTI defense).
- [`add-runtime` export may not survive into the exact process herdr inspects (jail.nix script internals)] → Verify with `herdr agent explain`; fallback: thin outer launcher package wrapping the jailed pi with `export HERDR_AGENT=pi`.
- [Screen-manifest `blocked` detection is heuristic; unusual prompts may show idle; session-resume after herdr restart is lost (needs the socket reports)] → Accepted trade-off; herdr's own guidance: inspect panes before automated prompting. Filtered-proxy fallback exists if this hurts in practice.
- [gh OAuth token is readable inside the jail (readonly bind)] → Accepted user decision; exfiltratable by design (network on). Future hardening path: fine-grained PAT via the module's `environment.GH_TOKEN.file` + agenix, no redesign needed.
- [`openspec` deps could resolve outside the bound `lib/node_modules` root] → Covered by binding the root rather than the package dir; verify `openspec list` jailed.
- [Full `/nix/store` ro is broader than pi's closure] → Deliberate: evaluation of arbitrary locked inputs and dev shells need it; store paths contain no credentials (secrets decrypt at activation, not in store).
- [`make update` jailed would still work for public inputs] → Policy: host-side only; the jail's missing `access-tokens` already blocks private fetches; `make home-build` inside jail still auto-locks newly added *public* inputs when flake.nix is edited.
- [herdr SKILL.md teaches control commands that fail in jail] → Cosmetic noise; commands fail fast. Optional later: annotate the skill file.
- [tmpfs HOME may surprise tools that write to `$HOME` outside the agent dir] → Known jail.nix behavior; pi writes only to the agent dir (mounted rw); nix cache is explicitly bound.

## Migration Plan

See D7 for the ordered cutover with rollback. Implementation is staged so that every step before user activation is pure build/verification (`make home-build`, `make os-build`), activation (`make home`, `make os`) is user-run per repo guardrails, and destructive cleanup happens only after jailed verification passes.

## Open Questions

- Annotate the herdr SKILL.md (or its generating derivation) to note that control commands are inert under the jail? Cosmetic; can be answered later without touching this design.
